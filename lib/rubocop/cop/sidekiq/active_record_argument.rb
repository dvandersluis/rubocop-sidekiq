require 'pry'

module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for ActiveRecord objects being passed as arguments to perform a Sidekiq
      # worker. ActiveRecord objects cannot be properly serialized into Redis, and therefore
      # should not be used. Instead of passing in an instantiated ActiveRecord object, pass
      # an ID and instantiate the AR object in the worker.
      #
      # @example
      #   # bad
      #   MyWorker.perform_async(Post.find(5))
      #   MyWorker.perform_async(Post.last(3))
      #
      #   # good
      #   MyWorker.perform_async(5)
      class ActiveRecordArgument < ::RuboCop::Cop::Cop
        include Helpers
        include CheckAssignment

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

        def_node_matcher :ar_method_call?, <<~PATTERN
          (send `{const #ar_var?} #ar_method? ...)
        PATTERN

        def_node_matcher :ar_default_value?, <<~PATTERN
          ({optarg kwoptarg} _ #ar_method_call?)
        PATTERN

        def_node_matcher :ar_var?, <<~PATTERN
          ({ivar lvar cvar gvar} #ar_identifier?)
        PATTERN

        def_node_matcher :metaprogrammed_var?, <<~PATTERN
          (send _ {:instance_variable_set :class_variable_set}
            $({sym str} _)
            #ar_method_call?
          )
        PATTERN

        def_node_matcher :ar?, <<~PATTERN
          {#ar_method_call? #ar_var?}
        PATTERN

        def_node_matcher :method_returning_ar?, <<~PATTERN
          (def ... {#ar_return? #ar_implicit_return?})
        PATTERN

        def_node_matcher :method_with_internal_ar?, <<~PATTERN
          {
            (def ... `#ar_method_call?)
            (def _ (args <#ar_default_value? ...>) ...)
          }
        PATTERN

        def_node_search :ar_method_calls, <<~PATTERN
          #ar_method_call?
        PATTERN

        def_node_search :ar_invocations, <<~PATTERN
          {
            #ar_method_call?
            (^args `#ar_method_call?)
            #ar_var?
            (send _ #ar_identifier?)
            (const _ #ar_identifier?)
          }
        PATTERN

        def on_send(node)
          return if track_metaprogramming_var(metaprogrammed_var?(node))
          return unless sidekiq_perform?(node)

          process_arguments(node)
        end

        def on_def(node)
          return unless detect_local_identifiers?
          return unless method_with_internal_ar?(node)

          find_method_default_vars(node.arguments)
          find_method_body_vars(node.body)

          add_ar_identifier(node.method_name) if method_returning_ar?(node)
        end

        def on_masgn(node)
          return unless detect_local_identifiers?

          rhs = extract_rhs(node)
          rhs = rhs.array_type? ? rhs.values : [rhs]

          return unless rhs.any? { |x| ar_method_call?(x) }

          values = extract_masgn_values(*node).select { |_, val| ar_method_call?(val) }
          values.each do |identifier, _|
            add_ar_identifier(identifier)
          end
        end

        def check_assignment(node, rhs)
          return unless detect_local_identifiers?
          return unless rhs
          return unless ar_method_call?(rhs)

          add_ar_identifier(extract_var_name(node))
        end

      private

        def detect_local_identifiers?
          # Should rubocop search for local methods and variables that contain offenses?
          cop_config['DetectLocalIdentifiers']
        end

        def arguments_of(node)
          detect_local_identifiers? ? ar_invocations(node) : ar_method_calls(node)
        end

        def process_arguments(node)
          arguments_of(node).each do |arg|
            next if node_denied?(arg)

            if ar?(arg) && chained?(arg, node) && !in_chain_returning_ar?(arg, node)
              approve_node(arg)
              next
            end

            add_offense(arg)
            deny_node(arg)
          end
        end

        def ar_method?(sym)
          ACTIVE_RECORD_METHODS.include?(sym)
        end

        def ar_return?(node)
          if node.return_type?
            return true if node.arguments.any? { |arg| ar?(arg) }
          else
            node.each_descendant(:return) do |ret|
              return true if ret.arguments.any? { |arg| ar?(arg) }
            end
          end

          nil
        end

        def ar_implicit_return?(node)
          node = node.children.last if node.begin_type?
          ar?(node)
        end

        def chained?(node, parent)
          node.each_ancestor(:send) do |ancestor|
            return true if ancestor != parent
          end

          false
        end

        def in_chain_returning_ar?(node, parent)
          prev = node
          outer_method = node.send_type? ? node.method_name : nil

          node.each_ancestor(:send) do |ancestor|
            break if ancestor == parent
            break if ancestor.receiver != prev

            outer_method = ancestor.method_name
          end

          outer_method && ACTIVE_RECORD_METHODS.include?(outer_method)
        end

        def add_ar_identifier(identifier)
          @ar_identifiers ||= []
          @ar_identifiers << identifier
        end

        def ar_identifier?(identifier)
          Array(@ar_identifiers).include?(identifier)
        end

        def extract_var_name(node)
          node = node.to_a.first if node.shorthand_asgn? || node.splat_type?

          if node.casgn_type?
            node.children[1]
          elsif node.optional_arg? || node.assignment?
            node.children.first
          end
        end

        def extract_masgn_values(lhs, rhs) # rubocop:disable Metrics/MethodLength
          lhs_values = lhs.to_a
          rhs_values = rhs.array_type? ? rhs.values : [rhs]

          lhs_values.each.with_index.with_object({}) do |(lval, i), hash|
            rval = if lval.splat_type?
              splat = rhs_values[i..-1]
              splat.empty? ? rhs_values[-1] : splat
            else
              rhs_values[i]
            end

            hash[extract_var_name(lval)] = rval
          end
        end

        def find_method_default_vars(args)
          args.each do |arg|
            next unless ar_default_value?(arg)
            add_ar_identifier(extract_var_name(arg))
          end
        end

        def find_method_body_vars(method)
          method.each_descendant(*RuboCop::AST::Node::ASSIGNMENTS) do |node|
            check_assignment(node, extract_rhs(node))
          end
        end

        def track_metaprogramming_var(var)
          return false unless var
          add_ar_identifier(var.value.to_sym)
        end
      end
    end
  end
end
