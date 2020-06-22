RSpec.describe RuboCop::Cop::Sidekiq::KeywordArguments do
  subject(:cop) { described_class.new }

  context 'in a sidekiq worker' do
    context 'perform method' do
      context 'no parameters' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform
              end
            end
          RUBY
        end
      end

      context 'normal param' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(foo)
              end
            end
          RUBY
        end
      end

      context 'splat param' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(*args)
              end
            end
          RUBY
        end
      end

      context 'kwarg' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(foo:)
                          ^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg with default' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(foo: :bar)
                          ^^^^^^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg splat unnamed' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(**)
                          ^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg splat named' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(**kwargs)
                          ^^^^^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end

      context 'multiple kwargs' do
        it 'registers multiple offenses' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(foo:, bar: 7, **rest)
                          ^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
                                ^^^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
                                        ^^^^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end

      context 'mixed parameters' do
        it 'registers offenses only on kwargs' do
          expect_offense(<<~RUBY)
            class TestWorker
              include Sidekiq::Worker

              def perform(a, *b, c:, **d)
                                 ^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
                                     ^^^ Keyword arguments are not allowed in a sidekiq worker's perform method.
              end
            end
          RUBY
        end
      end
    end

    context 'in another method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class TestWorker
            include Sidekiq::Worker

            def foo(a:)
            end
          end
        RUBY
      end
    end
  end

  context 'perform method in another class' do
    it 'does not register an offense for a kwarg' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def perform(kwarg1:, kwarg2: 5, **rest)
          end
        end
      RUBY
    end
  end
end
