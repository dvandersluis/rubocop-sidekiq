module RuboCop
  module Cop
    module Sidekiq
      class InlinePerform < RuboCop::Cop::Cop
        MSG = 'Do not run a Sidekiq worker inline.'.freeze

        def_node_matcher :inline_perform?, <<~PATTERN
          (send $_ :perform ...)
        PATTERN

        def on_send(node)
          return unless (receiver = inline_perform?(node))
          return if receiver.const_type?

          add_offense(node)
        end
      end
    end
  end
end
