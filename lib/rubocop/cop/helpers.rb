module RuboCop
  module Cop
    module Sidekiq
      module Helpers
        SIDEKIQ_INCLUDE_PATTERN = <<~PATTERN.freeze
          (send nil? :include (const (const nil? :Sidekiq) :Worker))
        PATTERN

        SIDEKIQ_WORKER_PATTERN = <<~PATTERN.freeze
          (class _ _
            {
              (begin <#sidekiq_include? ...>)
              #sidekiq_include?
            }
          )
        PATTERN

        SIDEKIQ_PERFORM_PATTERN = <<~PATTERN.freeze
          (send const {:perform_async :perform_in :perform_at} ...)
        PATTERN

        def self.included(klass)
          klass.def_node_matcher(:sidekiq_include?, SIDEKIQ_INCLUDE_PATTERN)
          klass.def_node_matcher(:sidekiq_worker?, SIDEKIQ_WORKER_PATTERN)
          klass.def_node_matcher(:sidekiq_perform?, SIDEKIQ_PERFORM_PATTERN)
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
