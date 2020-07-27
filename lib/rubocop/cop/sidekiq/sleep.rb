module RuboCop
  module Cop
    module Sidekiq
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
