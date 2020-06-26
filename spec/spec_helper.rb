require 'rubocop-sidekiq'
require 'rubocop/rspec/support'

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }
Dir[File.expand_path('shared_examples/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching(:focus)
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand(config.seed)

  config.extend(EachPerformMethod)
end
