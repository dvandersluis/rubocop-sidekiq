module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for calls to `sleep` or `Kernel.sleep` within a Sidekiq worker. Rather than
      # pausing sidekiq execution, it's better to schedule a job to occur later.
      #
      # @example
      #   # bad
      #   class MyWorker
      #     include Sidekiq::Worker
      #
      #     def perform
      #       # do work
      #       sleep(5.minutes)
      #       # do more work
      #     end
      #   end
      #
      #   # good
      #   class MyWorker
      #     include Sidekiq::Worker
      #
      #     def perform
      #       # do work
      #       AdditionalWorkWorker.perform_in(5.minutes)
      #     end
      #   end
      class Sleep < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Do not call `sleep` inside a sidekiq worker, schedule a job instead.'.freeze

        def_node_matcher :sleep?, <<~PATTERN
          (send {(const _ :Kernel) nil?} :sleep ...)
        PATTERN

        def on_send(node)
          return unless sleep?(node)
          return unless in_sidekiq_worker?(node)

          add_offense(node)
        end
      end
    end
  end
end
