module RuboCop
  module Cop
    module Sidekiq
      module Helpers
        NODE_MATCHERS = lambda do
          def_node_matcher :sidekiq_include?, <<~PATTERN
            (send nil? :include (const (const nil? :Sidekiq) :Worker))
          PATTERN

          def_node_matcher :sidekiq_worker?, <<~PATTERN
            (class _ _
              {
                (begin <#sidekiq_include? ...>)
                #sidekiq_include?
              }
            )
          PATTERN

          def_node_matcher :sidekiq_perform?, <<~PATTERN
            (send const ${:perform_async :perform_in :perform_at} ...)
          PATTERN
        end

        def self.included(klass)
          klass.class_exec(&NODE_MATCHERS)
        end

        def sidekiq_arguments(node)
          return [] unless node.send_type? && (method_name = sidekiq_perform?(node))

          # Drop the first argument for perform_at and perform_in
          expand_arguments(method_name == :perform_async ? node.arguments : node.arguments[1..-1])
        end

        def expand_arguments(arguments)
          arguments.flat_map do |argument|
            if argument.array_type? || argument.hash_type?
              expand_arguments(argument.values)
            else
              argument
            end
          end
        end

        def node_approved?(node)
          @approved_nodes ||= []
          @approved_nodes.any? { |r| within?(node.source_range, r) }
        end
        alias_method :node_denied?, :node_approved?

        def approve_node(node)
          @approved_nodes ||= []
          @approved_nodes << node.source_range
        end
        alias_method :deny_node, :approve_node

        def within?(inner, outer)
          inner.begin_pos >= outer.begin_pos && inner.end_pos <= outer.end_pos
        end
      end
    end
  end
end
