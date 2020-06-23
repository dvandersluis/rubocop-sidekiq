require 'rubocop/ast/node'

module RuboCop
  module AST
    class Node < Parser::AST::Node
      OPTIONAL_ARGS = %i(optarg kwoptarg).freeze

      def optional_arg?
        OPTIONAL_ARGS.include?(type)
      end
    end
  end
end
