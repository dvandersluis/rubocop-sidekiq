module RuboCop
  module Cop
    module Sidekiq
      class SymbolArgument < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Symbols are not Sidekiq-serializable; use strings instead.'.freeze

        def on_send(node)
          sidekiq_arguments(node).each do |argument|
            add_offense(argument) if argument.sym_type?
          end
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.source_range, to_string_literal(node.value.to_s))
          end
        end
      end
    end
  end
end
