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
          MyWorker.perform(Time.now)
                           ^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'Date.today' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Date.today)
                           ^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'Date.tomorrow' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Date.tomorrow)
                           ^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'DateTime.now' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(DateTime.now)
                           ^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'ActiveSupport::TimeWithZone.new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(ActiveSupport::TimeWithZone.new)
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end

      it 'can be cast' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(ActiveSupport::TimeWithZone.new.to_i)
        RUBY
      end
    end

    context '::ActiveSupport::TimeWithZone.new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(::ActiveSupport::TimeWithZone.new)
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end

    context 'cast to integer' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(Time.now.to_i)
        RUBY
      end
    end

    context 'cast to string' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(Time.now.to_s)
        RUBY
      end
    end

    context 'instance' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Time.new(2020,6,1))
                           ^^^^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
        RUBY
      end
    end
    context 'durations' do
      context 'ActiveSupport::Duration.new' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(ActiveSupport::Duration.new)
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Durations are not Sidekiq-serializable; use the integer instead.
          RUBY
        end
      end

      context '::ActiveSupport::Duration.new' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(::ActiveSupport::Duration.new)
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Durations are not Sidekiq-serializable; use the integer instead.
          RUBY
        end
      end

      context 'ActiveSupport::Duration.hours' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(ActiveSupport::Duration.hours)
                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Durations are not Sidekiq-serializable; use the integer instead.
          RUBY
        end
      end

      context 'numeric duration' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(1.hour)
                             ^^^^^^ Durations are not Sidekiq-serializable; use the integer instead.
          RUBY
        end
      end

      context 'ago' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(1.hour.ago)
                             ^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
          RUBY
        end
      end

      context 'from_now' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(1.hour.from_now)
                             ^^^^^^^^^^^^^^^ Date/Time objects are not Sidekiq-serializable; convert to integers or strings instead.
          RUBY
        end
      end

      context ''
    end

    context 'when AllowedMethods is set' do
      let(:cop_config) { { 'AllowedMethods' => %w(foo bar) } }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(Time.foo)
          MyWorker.perform(Time.bar)
          MyWorker.perform(Time.now.to_s)
        RUBY
      end
    end
  end
end
