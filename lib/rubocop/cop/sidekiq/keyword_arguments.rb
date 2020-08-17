module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for Sidekiq worker `perform` methods that use keyword args. Keyword args
      # cannot be properly serialized to Redis and are thus not recommended. Use regular arguments
      # instead.
      #
      # @example
      #   # bad
      #   class MyWorker
      #     include Sidekiq::Worker
      #
      #     def perform(id:, keyword_with_default: false, **other_kwargs)
      #     end
      #   end
      #
      #   # good
      #   class MyWorker
      #     include Sidekiq::Worker
      #
      #     def perform(id, arg_with_default = false, *other_args)
      #     end
      #   end
      class KeywordArguments < ::RuboCop::Cop::Cop
        include Helpers

        MSG = "Keyword arguments are not allowed in a sidekiq worker's perform method.".freeze
        KWARG_TYPES = %i(kwarg kwoptarg kwrestarg).freeze

        def_node_matcher :perform_with_kwargs?, <<~PATTERN
          (def :perform (args ... {kwarg kwoptarg kwrestarg}) ...)
        PATTERN

        def on_def(node)
          return unless perform_with_kwargs?(node)
          return unless in_sidekiq_worker?(node)

          node.arguments.each do |arg|
            next unless KWARG_TYPES.include?(arg.type)
            add_offense(arg)
          end
        end
      end
    end
  end
end
