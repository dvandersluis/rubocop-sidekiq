RSpec.describe RuboCop::Cop::Sidekiq::Sleep do
  subject(:cop) { described_class.new }

  context 'in a sidekiq job' do
    context 'implicit sleep' do
      let(:source) do
        <<~RUBY
          class MyJob
            include Sidekiq::Job

            def wait
              sleep 5
              ^^^^^^^ Do not call `sleep` inside a sidekiq job, schedule a job instead.
            end

            def perform
              wait
            end
          end
        RUBY
      end

      it 'registers an offense' do
        expect_offense(source)
      end
    end

    context 'explicit sleep' do
      let(:source) do
        <<~RUBY
          class MyJob
            include Sidekiq::Job

            def wait
              Kernel.sleep 5
              ^^^^^^^^^^^^^^ Do not call `sleep` inside a sidekiq job, schedule a job instead.
            end

            def perform
              wait
            end
          end
        RUBY
      end

      it 'registers an offense' do
        expect_offense(source)
      end
    end
  end

  context 'outside a sidekiq job' do
    let(:source) do
      <<~RUBY
        class Class
          def wait
            sleep 5
          end

          def perform
            wait
          end
        end
      RUBY
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end

  context 'external method called sleep' do
    let(:source) do
      <<~RUBY
        class Class
          def wait
            Foo.sleep 5
          end

          def perform
            wait
          end
        end
      RUBY
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end
end
