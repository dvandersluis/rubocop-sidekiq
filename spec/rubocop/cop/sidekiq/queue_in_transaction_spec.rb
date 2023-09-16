RSpec.describe RuboCop::Cop::Sidekiq::QueueInTransaction do
  subject(:cop) { described_class.new }

  each_perform_method(rewrite_mode: :extend) do
    context 'model-less transaction' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          ActiveRecord::Base.transaction do
            MyJob.perform
            ^^^^^^^^^^^^^^^^ Do not queue a job inside a transaction.
          end
        RUBY
      end
    end

    context 'model transaction' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          Post.transaction do
            MyJob.perform
            ^^^^^^^^^^^^^^^^ Do not queue a job inside a transaction.
          end
        RUBY
      end
    end

    context 'local transaction' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          transaction do
            MyJob.perform
            ^^^^^^^^^^^^^^^^ Do not queue a job inside a transaction.
          end
        RUBY
      end
    end

    context 'complex transaction' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          transaction do
            Post.do_something
            MyJob.perform
            ^^^^^^^^^^^^^^^^ Do not queue a job inside a transaction.
          end
        RUBY
      end
    end

    context 'perform after transaction' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          transaction do
            Post.do_something
          end

          MyJob.perform
        RUBY
      end
    end
  end
end
