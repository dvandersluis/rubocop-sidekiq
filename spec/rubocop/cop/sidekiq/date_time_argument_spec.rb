RSpec.describe RuboCop::Cop::Sidekiq::DateTimeArgument do
  let(:config) do
    RuboCop::Config.new('Sidekiq/DateTimeArgument' => cop_config)
  end
  let(:cop_config) { {} }

  subject(:cop) { described_class.new(config) }

  each_perform_method do
    context 'Time.now' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Time.now)
                   #{_______} ^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'DateTime.now' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(DateTime.now)
                   #{_______} ^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'ActiveSupport::TimeWithZone.new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(ActiveSupport::TimeWithZone.new)
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end

      it 'can be cast' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(ActiveSupport::TimeWithZone.new.to_i)
        RUBY
      end
    end

    context '::ActiveSupport::TimeWithZone.new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(::ActiveSupport::TimeWithZone.new)
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'cast to integer' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(Time.now.to_i)
        RUBY
      end
    end

    context 'cast to string' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(Time.now.to_s)
        RUBY
      end
    end

    context 'when AllowedMethods is set' do
      let(:cop_config) { { 'AllowedMethods' => %w(foo bar) } }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(Time.foo)
          MyWorker.#{perform}(Time.bar)
          MyWorker.#{perform}(Time.now.to_s)
        RUBY
      end
    end
  end
end
