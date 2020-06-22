module RuboCop
  module Cop
    module Sidekiq
      class ConstArgument < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Objects are not Sidekiq-serializable.'.freeze

        def_node_matcher :initializer?, <<~PATTERN
          (send const :new)
        PATTERN

        def_node_matcher :constant?, <<~PATTERN
          (const _ _)
        PATTERN

        def on_send(node)
          return unless sidekiq_perform?(node)

          node.arguments.each do |arg|
            next unless initializer?(arg) || constant?(arg)
            next if arg.source =~ /\A[A-Z0-9_]+\z/

            add_offense(arg)
          end
        end
      end
    end
  end
end
