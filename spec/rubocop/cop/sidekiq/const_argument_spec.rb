RSpec.describe RuboCop::Cop::Sidekiq::ConstArgument do
  subject(:cop) { described_class.new }

  each_perform_method do
    context 'with a class argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Object)
                           ^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'with .new' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Object.new)
                           ^^^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end

      context 'on a namespace' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            MyWorker.perform(Foo::Bar.new)
                             ^^^^^^^^^^^^ Objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'with a method chain' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            MyWorker.perform(Object.new.id)
          RUBY
        end
      end
    end

    context 'with self' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(self)
                           ^^^^ `self` is not Sidekiq-serializable.
        RUBY
      end
    end

    context 'self-referential' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(MyWorker)
                           ^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'namespaced class' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.perform(Namespace::Class)
                           ^^^^^^^^^^^^^^^^ Objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'with a constant' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(MY_CONSTANT)
        RUBY
      end
    end

    context 'with a method other than new' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(Foo.bar)
        RUBY
      end
    end

    context 'with a method other than new and a namespace' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(Foo::Bar.baz)
        RUBY
      end
    end

    context 'with a namespaced constant' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.perform(MyClass::MY_CONSTANT)
        RUBY
      end
    end

    it_behaves_like 'nested unserializable', 'Object.new', 'Objects are not Sidekiq-serializable.'
  end
end
