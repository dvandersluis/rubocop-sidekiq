RSpec.describe RuboCop::Cop::Sidekiq::IncludedInModule do
  let(:config) do
    RuboCop::Config.new('Sidekiq/IncludedInModule' => cop_config)
  end
  let(:cop_config) { {} }

  subject(:cop) { described_class.new(config) }

  context 'module with sidekiq include' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        module TestJob
          include Sidekiq::Job
          ^^^^^^^^^^^^^^^^^^^^^^^ Do not include Sidekiq::Job in a module.
        end
      RUBY
    end
  end

  context 'anonymous module with sidekiq include' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        TestJob = Module.new do
          include Sidekiq::Job
          ^^^^^^^^^^^^^^^^^^^^^^^ Do not include Sidekiq::Job in a module.
        end
      RUBY
    end
  end

  context 'module without sidekiq include' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        module TestJob
        end
      RUBY
    end
  end

  context 'anonymous module without sidekiq include' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        TestJob = Module.new do
        end
      RUBY
    end
  end

  context 'class with sidekiq include' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class TestJob
          include Sidekiq::Job
        end
      RUBY
    end
  end

  context 'Whitelist' do
    let(:cop_config) { { 'Whitelist' => %w(Sidekiqable) } }

    context 'with a whitelisted module' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          module Sidekiqable
            include Sidekiq::Job
          end
        RUBY
      end
    end

    context 'with a whitelisted anonymous module' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          Sidekiqable = Module.new do
            include Sidekiq::Job
          end
        RUBY
      end
    end

    context 'with an anonymous module' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          Module.new do
            include Sidekiq::Job
            ^^^^^^^^^^^^^^^^^^^^^^^ Do not include Sidekiq::Job in a module.
          end
        RUBY
      end
    end
  end
end
