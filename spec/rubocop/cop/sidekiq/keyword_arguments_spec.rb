RSpec.describe RuboCop::Cop::Sidekiq::KeywordArguments do
  subject(:cop) { described_class.new }

  context 'in a sidekiq job' do
    context 'perform method' do
      context 'no parameters' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform
              end
            end
          RUBY
        end
      end

      context 'normal param' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(foo)
              end
            end
          RUBY
        end
      end

      context 'splat param' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(*args)
              end
            end
          RUBY
        end
      end

      context 'kwarg' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(foo:)
                          ^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg with default' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(foo: :bar)
                          ^^^^^^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg splat unnamed' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(**)
                          ^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end

      context 'kwarg splat named' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(**kwargs)
                          ^^^^^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end

      context 'multiple kwargs' do
        it 'registers multiple offenses' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(foo:, bar: 7, **rest)
                          ^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
                                ^^^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
                                        ^^^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end

      context 'mixed parameters' do
        it 'registers offenses only on kwargs' do
          expect_offense(<<~RUBY)
            class TestJob
              include Sidekiq::Job

              def perform(a, *b, c:, **d)
                                 ^^ Keyword arguments are not allowed in a sidekiq job's perform method.
                                     ^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          RUBY
        end
      end
    end

    context 'in another method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class TestJob
            include Sidekiq::Job

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

  context 'in an inner class' do
    context 'kwarg in inner class' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          class Foo
            class TestJob
              include Sidekiq::Job

              def perform(foo:)
                          ^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
              end
            end
          end
        RUBY
      end
    end

    context 'kwarg in outer class' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          class Foo
            class TestJob
              include Sidekiq::Job
            end

            def perform(foo:)
            end
          end
        RUBY
      end
    end
  end

  context 'in a Class.new class' do
    context 'that is a sidekiq job' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          Class.new do
            include Sidekiq::Job

            def perform(**kwargs)
                        ^^^^^^^^ Keyword arguments are not allowed in a sidekiq job's perform method.
            end
          end
        RUBY
      end
    end

    context 'that is not a sidekiq job' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          Class.new do
            def perform(**kwargs)
            end
          end
        RUBY
      end
    end
  end
end
