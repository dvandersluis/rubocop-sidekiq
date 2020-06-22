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
      end
    end
  end
end
