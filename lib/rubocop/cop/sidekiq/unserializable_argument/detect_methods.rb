module RuboCop
  module Cop
    module Sidekiq
      module UnserializableArgument
        class DetectMethods
          extend RuboCop::AST::NodePattern::Macros
          extend Forwardable

          def_node_search :method_definitions, <<~PATTERN
            {
              (def _ _+)
              (defs _ _ ...)
              (block (send _ :define_method ...) ...)
            }
          PATTERN

          attr_reader :cop

          def_delegators :cop, :s

          def initialize(cop)
            @cop = cop
          end

          def call(ast)
            return {} if ast.nil?

            method_definitions(ast).each_with_object({}) do |method, map|
              returns = return_values(method.body)
              next if returns.nil? || returns.empty?

              map[rewrite_node(method)] = returns
            end
          end

        private

          def return_values(node)
            return nil if node.nil?

            returns = []

            if node.return_type?
              returns = return_values_for(node)
            else
              returns.concat(return_values_for(*node.each_descendant(:return)))
              returns.concat(return_values_for(node.begin_type? ? node.children.last : node))
            end

            returns.uniq
          end

          def return_values_for(*nodes)
            return [] if nodes.empty?

            nodes.flat_map { |node| node_values(node) }.
              select { |node| cop.potentially_unserializable?(node) }
          end

          def node_values(node)
            if node.return_type?
              return_values_for(*node.arguments)
            elsif node.array_type? || node.hash_type?
              sanitize_nodes(*node.values)
            else
              sanitize_nodes(node)
            end
          end

          def sanitize_nodes(*nodes)
            nodes.map do |node|
              if node.send_type?
                # Remove any arguments from send nodes
                s(:send, node.receiver, node.method_name)
              else
                node
              end
            end
          end

          # Rewrite the node from a `def`/`block` node to a `send` node, so that nodes can
          # be found more easily when searching the map
          def rewrite_node(node)
            if node.block_type?
              s(:send, method_receiver(node.send_node), node.send_node.arguments.first.value)
            else
              s(:send, method_receiver(node), node.method_name)
            end
          end

          def method_receiver(node)
            # TODO: handle finding the receiver from a method within a class
            # How to handle methods in modules that are mixed in?
            node.receiver
          end
        end
      end
    end
  end
end
