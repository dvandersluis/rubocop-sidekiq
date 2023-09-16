module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for jobs being queued within a transaction. Queueing should not occur
      # within a transaction, because even if the transaction is rolled back, the job will still
      # persist. Additionally, this may cause errors where a job is run for a given record, before
      # the transaction is committed.
      #
      # @example
      #   # bad
      #   ActiveRecord::Base.transaction do
      #     record.save
      #     MyJob.perform_async(record.id)
      #   end
      #
      #   # bad
      #   transaction do
      #     record.save
      #     MyJob.perform_async(record.id)
      #   end
      #
      #   # good
      #   ActiveRecord::Base.transaction.do
      #     record.save
      #   end
      #   MyJob.perform_async(record.id) if record.persisted?
      #
      #   # good
      #   ActiveRecord::Base.transaction.do
      #     Post.create(...)
      #   end
      #
      #   class Post < ApplicationRecord
      #     after_commit(on: :create) { MyJob.perform_async(id) }
      #   end
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
