module RuboCop
  module Cop
    module Sidekiq
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
