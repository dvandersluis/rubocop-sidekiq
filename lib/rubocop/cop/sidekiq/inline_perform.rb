module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for Sidekiq jobs being instantiated and performed inline, rather than
      # asynchronously.
      #
      # Test files are excluded from this cop, by default.
      #
      # @example
      #   # bad
      #   MyJob.new.perform
      #
      #   # good
      #   MyJob.perform_async
      #   MyJob.perform_in(3.hours)
      class InlinePerform < RuboCop::Cop::Cop
        MSG = 'Do not run a Sidekiq job inline.'.freeze

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
