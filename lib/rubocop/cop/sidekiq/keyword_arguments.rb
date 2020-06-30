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
          return unless sidekiq_worker?(find_class(node))

          node.arguments.each do |arg|
            next unless KWARG_TYPES.include?(arg.type)
            add_offense(arg)
          end
        end

      private

        def find_class(node)
          node.each_ancestor(:class, :block).detect { |anc| sidekiq_worker?(anc) }
        end
      end
    end
  end
end
