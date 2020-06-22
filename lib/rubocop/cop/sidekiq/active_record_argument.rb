module RuboCop
  module Cop
    module Sidekiq
      class ActiveRecordArgument < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'ActiveRecord objects are not Sidekiq-serializable.'.freeze

        # Methods are a subset of ActiveRecord::Querying::QUERYING_METHODS that return AR objec
        ACTIVE_RECORD_METHODS = %i(
          all find find_by find_by! take take! first first! last last!
          second second! third third! fourth fourth! fifth fifth!
          forty_two forty_two! third_to_last third_to_last! second_to_last second_to_last!
          first_or_create first_or_create! first_or_initialize
          find_or_create_by find_or_create_by! find_or_initialize_by
          create_or_find_by create_or_find_by!
          destroy_by delete_by
          find_each find_in_batches in_batches
          select reselect order reorder group limit offset joins left_joins left_outer_joins
          where rewhere preload extract_associated eager_load includes from lock readonly extending or
          having create_with distinct references none unscope optimizer_hints merge except only
        ).freeze

        def_node_search :ar_method_calls, <<~PATTERN
          (send `const #ar_method? ...)
        PATTERN

        def on_send(node)
          return unless sidekiq_perform?(node)

          ar_method_calls(node).each do |arg|
            next if node_denied?(arg)

            add_offense(arg)
            deny_node(arg)
          end
        end

      private

        def ar_method?(sym)
          ACTIVE_RECORD_METHODS.include?(sym)
        end
      end
    end
  end
end
