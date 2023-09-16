module RuboCop
  module Cop
    module Sidekiq
      # This cop checks for `include Sidekiq::Job` in a module. Modules are not instantiable,
      # which means that if a module is attempted to be queued, Sidekiq will error trying to
      # run the job.
      #
      # Modules intended for use with Sidekiq job inheritance can be allowed by adding
      # it to the Whitelist.
      #
      # @example
      #   # bad
      #   module MyJob
      #     include Sidekiq::Job
      #   end
      #
      #   # good
      #   class MyJob
      #     include Sidekiq::Job
      #   end
      #
      # @example Whitelist: ['AbstractJob']
      #  # good
      #  module AbstractJob
      #    include Sidekiq::Job
      #  end
      class IncludedInModule < ::RuboCop::Cop::Cop
        include Helpers

        MSG = 'Do not include Sidekiq::Job in a module.'.freeze

        def_node_matcher :module_include?, <<~PATTERN
          {
            (module _ $#includes_sidekiq?)
            (block (send (const nil? :Module) :new ...) _ $#includes_sidekiq?)
          }
        PATTERN

        def on_module(node)
          return unless (include = module_include?(node))
          return if allowed_module?(node)

          add_offense(include)
        end
        alias_method :on_block, :on_module

      private

        def allowed_module_names
          Array(cop_config['Whitelist']).map(&:to_s)
        end

        def allowed_module?(node)
          identifier = module_identifier(node)
          return false unless identifier

          allowed_module_names.include?(identifier)
        end

        def module_identifier(node)
          if node.module_type?
            node.identifier.const_name
          elsif node.block_type?
            node.parent.defined_module_name if node.parent && node.parent.casgn_type?
          end
        end
      end
    end
  end
end
