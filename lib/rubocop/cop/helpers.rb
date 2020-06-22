module RuboCop
  module Cop
    module Sidekiq
      module Helpers
        def self.included(klass)
          klass.def_node_matcher(:sidekiq_include?, <<~PATTERN)
            (send nil? :include (const (const nil? :Sidekiq) :Worker))
          PATTERN

          klass.def_node_matcher(:sidekiq_worker?, <<~PATTERN)
            (class ... `$#sidekiq_include?)
          PATTERN

          klass.def_node_matcher(:sidekiq_perform?, <<~PATTERN)
            (send const {:perform_async :perform_in :perform_at} ...)
          PATTERN
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
