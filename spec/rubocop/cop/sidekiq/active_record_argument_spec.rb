RSpec.describe RuboCop::Cop::Sidekiq::ActiveRecordArgument do
  subject(:cop) { described_class.new }

  each_perform_method do
    context 'Model.find' do
      it 'raises an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.find(5))
                   #{_______} ^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'Model.all' do
      it 'raises an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.all)
                   #{_______} ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain' do
      it 'raises an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.where(foo: :bar).first)
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain with non-disallowed method' do
      it 'raises an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.my_scope.last(3))
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR method called as an instance method' do
      it 'does not raise an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(foo.find)
        RUBY
      end
    end
  end
end
