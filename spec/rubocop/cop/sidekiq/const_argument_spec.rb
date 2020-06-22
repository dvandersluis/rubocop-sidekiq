RSpec.describe RuboCop::Cop::Sidekiq::ConstArgument do
  subject(:cop) { described_class.new }

  each_perform_method do
    context 'with a class argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Object)
                   #{_______} ^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'with .new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Object.new)
                   #{_______} ^^^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'with .new and a namespace' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Foo::Bar.new)
                   #{_______} ^^^^^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'self-referential' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(MyWorker)
                   #{_______} ^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'with a constant' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(MY_CONSTANT)
        RUBY
      end
    end

    context 'with a method other than new' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(Foo.bar)
        RUBY
      end
    end

    context 'with a method other than new and a namespace' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(Foo::Bar.baz)
        RUBY
      end
    end
  end
end
