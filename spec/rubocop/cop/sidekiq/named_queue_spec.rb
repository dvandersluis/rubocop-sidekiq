RSpec.describe RuboCop::Cop::Sidekiq::NamedQueue do
  let(:config) do
    RuboCop::Config.new('Sidekiq/NamedQueue' => cop_config)
  end
  let(:cop_config) { {} }

  subject(:cop) { described_class.new(config) }

  context 'default queue names' do
    let(:config) { RuboCop::Config.new(YAML.load_file('./config/default.yml')) }

    context 'queue named default' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :default
          end
        RUBY
      end
    end

    context 'queue named low' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :low
          end
        RUBY
      end
    end

    context 'queue named critical' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :critical
          end
        RUBY
      end
    end

    context 'queue named something else' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :foobar
                                   ^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
          end
        RUBY
      end

      context 'queue name is a string' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class MyJob
              include Sidekiq::Job

              sidekiq_options queue: 'foobar'
                                     ^^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
            end
          RUBY
        end
      end

      context 'queue key is a string' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class MyJob
              include Sidekiq::Job

              sidekiq_options 'queue' => :foobar
                                         ^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
            end
          RUBY
        end
      end

      context 'queue key and value are strings' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class MyJob
              include Sidekiq::Job

              sidekiq_options 'queue' => 'foobar'
                                         ^^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
            end
          RUBY
        end
      end

      context 'sidekiq_options has other keys' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class MyJob
              include Sidekiq::Job

              sidekiq_options queue: 'foobar', other: true
                                     ^^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
            end
          RUBY
        end
      end

      context 'sidekiq_options has other keys first' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class MyJob
              include Sidekiq::Job

              sidekiq_options other: true, queue: 'foobar'
                                                  ^^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: default, low, critical.
            end
          RUBY
        end
      end
    end
  end

  context 'configured queue names' do
    let(:cop_config) { { 'AllowedNames' => %w(low) } }

    context 'queue named default' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :default
                                   ^^^^^^^^ Do not add new named queues to sidekiq, they will not be processed by default. Allowed queues: low.
          end
        RUBY
      end
    end

    context 'queue named low' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class MyJob
            include Sidekiq::Job

            sidekiq_options queue: :low
          end
        RUBY
      end
    end
  end
end
