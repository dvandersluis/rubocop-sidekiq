module RuboCop
  module Cop
    module Sidekiq
      class QueueInTransaction < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Do not queue a job inside a transaction.'.freeze

        def_node_matcher :perform_in_transaction?, <<~PATTERN
          (block (send _ :transaction) ... {$#sidekiq_perform? (begin <$#sidekiq_perform? ...>)} )
        PATTERN

        def on_block(node)
          return unless (send_node = perform_in_transaction?(node))
          add_offense(send_node)
        end
      end
    end
  end
end
