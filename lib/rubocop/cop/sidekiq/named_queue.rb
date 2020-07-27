module RuboCop
  module Cop
    module Sidekiq
      class NamedQueue < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Do not add new queues to sidekiq.'.freeze

        def_node_matcher :named_queue?, <<~PATTERN
          (send _ :sidekiq_options (hash <(pair {(str "queue") (sym :queue)} ${(sym _) (str _)}) ...>))
        PATTERN

        def on_send(node)
          return unless (queue_name = named_queue?(node))
          return unless in_sidekiq_worker?(node)
          return if name_allowed?(queue_name)

          add_offense(queue_name)
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
