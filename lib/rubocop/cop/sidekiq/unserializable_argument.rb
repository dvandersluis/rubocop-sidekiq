require 'rubocop/cop/sidekiq/unserializable_argument/detect_methods'

module RuboCop
  module Cop
    module Sidekiq
      module UnserializableArgument
        NODE_MATCHERS = lambda do
          def_node_matcher :potentially_unserializable?, <<~PATTERN
            {
              #unserializable?
              {send lvar ivar cvar gvar const}
            }
          PATTERN
        end

        def self.included(klass)
          klass.class_exec(&NODE_MATCHERS)
          klass.attr_accessor(:identifier_map)
        end

        def investigate(processed_source)
          ast = processed_source.ast

          self.identifier_map = {}.merge(
            DetectMethods.new(self).call(ast)
          )
        end
      end
    end
  end
end
