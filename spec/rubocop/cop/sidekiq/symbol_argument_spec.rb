RSpec.describe RuboCop::Cop::Sidekiq::SymbolArgument do
  subject(:cop) { described_class.new }

  each_perform_method do
    context 'with symbol argument' do
      it 'registers an offense and corrects' do
        expect_offense(<<~RUBY)
          MyWorker.perform(:symbol)
                           ^^^^^^^ Symbols are not Sidekiq-serializable; use strings instead.
        RUBY

        expect_correction(<<~RUBY)
          MyWorker.perform('symbol')
        RUBY
      end
    end
  end
end
