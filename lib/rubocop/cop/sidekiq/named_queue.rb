module RuboCop
  module Cop
    module Sidekiq
      # This cop checks that sidekiq workers use queues that are predefined. Sidekiq states that
      # having many queues is not recommended due to complexity and overburdening Redis. Furthermore,
      # new queues may not be processed without being set up explicitly.
      #
      # @example
      #   # bad
      #   class MyWorker
      #     include Sidekiq::Worker
      #     sidekiq_options queue: 'high'
      #   end
      #
      #   # good
      #   class MyWorker
      #     include Sidekiq::Worker
      #   end
      #
      #   class MyWorker
      #     include Sidekiq::Worker
      #     sidekiq_options queue: 'low'
      #   end
      #
      # @example AllowedNames: ['high', 'low', 'default']
      #   # bad
      #   class MyWorker
      #     include Sidekiq::Worker
      #     sidekiq_options queue: 'critical'
      #   end
      #
      #   # good
      #   class MyWorker
      #     include Sidekiq::Worker
      #   end
      #
      #   class MyWorker
      #     include Sidekiq::Worker
      #     sidekiq_options queue: 'high'
      #   end
      class NamedQueue < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: %s.'.freeze

        def_node_matcher :named_queue?, <<~PATTERN
          (send _ :sidekiq_options (hash <(pair {(str "queue") (sym :queue)} ${(sym _) (str _)}) ...>))
        PATTERN

        def on_send(node)
          return unless (queue_name = named_queue?(node))
          return unless in_sidekiq_worker?(node)
          return if name_allowed?(queue_name)

          add_offense(queue_name, message: MSG % allowed_names.join(', '))
        end

      private

        def allowed_names
          Array(cop_config['AllowedNames'])
        end

        def name_allowed?(node)
          allowed_names.include?(node.value.to_s)
        end
      end
    end
  end
end
