module RuboCop
  module Cop
    module Sidekiq
      class ConstArgument < ::RuboCop::Cop::Cop
        CONSTANT_NAME = /\A[A-Z0-9_]+\z/.freeze

        include Helpers

        MSG = 'Objects are not Sidekiq-serializable.'.freeze
        MSG_SELF = '`self` is not Sidekiq-serializable.'.freeze

        def_node_matcher :initializer?, <<~PATTERN
          (send const :new)
        PATTERN

        def_node_matcher :constant?, <<~PATTERN
          (const _ _)
        PATTERN

        def_node_matcher :const_argument?, <<~PATTERN
          {#initializer? #constant? self}
        PATTERN

        def on_send(node)
          sidekiq_arguments(node).each do |arg|
            next unless const_argument?(arg)
            next if non_class_constant?(arg)

            add_offense(arg, message: arg.self_type? ? MSG_SELF : MSG)
          end
        end

      private

        def non_class_constant?(arg)
          arg.const_type? && arg.children[1].to_s =~ CONSTANT_NAME
        end
      end
    end
  end
end
