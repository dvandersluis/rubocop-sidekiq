module RuboCop
  module Cop
    module InternalAffairs
      class IncorrectExampleDescription < ::RuboCop::Cop::Cop
        POSITIVE_PREFIX = 'registers'.freeze
        NEGATIVE_PREFIX = 'does not register'.freeze
        POSITIVE_DESCS = [
          'registers an offense'.freeze,
          'registers an offense and corrects'.freeze
        ].freeze
        NEGATIVE_DESCS = [
          'does not register an offense'.freeze
        ].freeze

        MSG = 'Use an appropriate example description for %s.'.freeze

        def_node_matcher :rspec_example?, <<~PATTERN
          (block
            $(send nil? :it ...)
            _
            <(send nil? ${:expect_offense :expect_no_offenses} ...) ...>
          )
        PATTERN

        def on_block(node)
          return unless (send_node, method = rspec_example?(node))

          desc = example_description(send_node)

          return if correct_description?(desc, method)
          add_offense(node, location: offense_location(desc, send_node), message: MSG % method)
        end

        def autocorrect(node)
          example, method = rspec_example?(node)

          lambda do |corrector|
            desc = to_string_literal(correct_descriptions(method).first)

            if (str_node = example_description_node(example))
              autocorrect_str(corrector, desc, str_node)
            else
              autocorrect_send(corrector, desc, example)
            end
          end
        end

      private

        def strict?
          cop_config.fetch('Strict', true)
        end

        def correct_description?(desc, method)
          if strict?
            correct_descriptions(method).include?(desc)
          else
            desc.start_with?(correct_description_prefix(method))
          end
        end

        def correct_descriptions(method)
          case method
            when :expect_offense
              positive_descriptions

            when :expect_no_offenses
              negative_descriptions
          end
        end

        def correct_description_prefix(method)
          case method
            when :expect_offense
              positive_prefix

            when :expect_no_offenses
              negative_prefix
          end
        end

        def example_description(node)
          desc = example_description_node(node)
          desc ? desc.value : nil
        end

        def example_description_node(node)
          arg = node.arguments.first
          arg && arg.str_type? ? arg : nil
        end

        def offense_location(desc, send_node)
          desc ? send_node.arguments.first.loc.expression : send_node.loc.selector
        end

        def autocorrect_str(corrector, desc, node)
          corrector.replace(node.source_range, desc)
        end

        def autocorrect_send(corrector, desc, node)
          corrector.insert_after(node.loc.selector, " #{desc}")
          corrector.insert_after(node.loc.selector, ',') if node.arguments.any?
        end

        def positive_prefix
          cop_config.fetch('PositivePrefix', POSITIVE_PREFIX)
        end

        def negative_prefix
          cop_config.fetch('NegativePrefix', NEGATIVE_PREFIX)
        end

        def positive_descriptions
          Array(cop_config.fetch('PositiveDescriptions', POSITIVE_DESCS))
        end

        def negative_descriptions
          Array(cop_config.fetch('NegativeDescriptions', NEGATIVE_DESCS))
        end
      end
    end
  end
end
