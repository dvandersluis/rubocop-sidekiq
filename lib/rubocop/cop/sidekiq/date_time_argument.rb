module RuboCop
  module Cop
    module Sidekiq
      class DateTimeArgument < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.'.freeze
        ALLOWED_METHODS = %i(to_i to_s).freeze

        def_node_search :date_time_args, <<~PATTERN
          $(send
            `{
              (const _ {:Date :DateTime :Time})
              (const (const _ :ActiveSupport) :TimeWithZone)
            }
            ...
          )
        PATTERN

        def on_send(node)
          return unless sidekiq_perform?(node)
          return if node.arguments.none?

          date_time_args(node).each do |arg|
            next if node_approved?(arg)

            # If the outer send (ie. the last method in the chain) is in the allowed method
            # list, approve the node (so that sub chains aren't flagged).
            if allowed_methods.include?(arg.method_name)
              approve_node(arg)
              next
            end

            add_offense(arg)
          end
        end

        def allowed_methods
          Array(cop_config['AllowedMethods']).concat(ALLOWED_METHODS).map(&:to_sym)
        end
      end
    end
  end
end
