module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for Sidekiq job perform arguments that look like classes or modules.
      # These cannot be serialized for Redis, and should not be used with Sidekiq.
      #
      # Constants other than classes/modules are not flagged by this cop.
      #
      # @example
      #   # bad
      #   MyJob.perform_async(MyClass)
      #   MyJob.perform_async(MyModule)
      #   MyJob.perform_async(Namespace::Class)
      #
      #   # good
      #   MyJob.perform_async(MY_CONSTANT)
      #   MyJob.perform_async(MyClass::MY_CONSTANT)
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
