RSpec.describe RuboCop::Cop::Sidekiq::InlinePerform do
  subject(:cop) { described_class.new }

  context 'direct call' do
    context 'with arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.new.perform('foo')
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not run a Sidekiq worker inline.
        RUBY
      end
    end

    context 'without arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.new.perform
          ^^^^^^^^^^^^^^^^^^^^ Do not run a Sidekiq worker inline.
        RUBY
      end
    end
  end

  context 'call on a identifier' do
    context 'with arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          my_worker.perform('foo')
          ^^^^^^^^^^^^^^^^^^^^^^^^ Do not run a Sidekiq worker inline.
        RUBY
      end
    end

    context 'without arguments' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          my_worker.perform
          ^^^^^^^^^^^^^^^^^ Do not run a Sidekiq worker inline.
        RUBY
      end
    end
  end

  context 'class method' do
    context 'with arguments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyClass.perform('foo')
        RUBY
      end
    end

    context 'without arguments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyClass.perform
        RUBY
      end
    end
  end
end
