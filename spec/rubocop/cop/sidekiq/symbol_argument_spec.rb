RSpec.describe RuboCop::Cop::Sidekiq::SymbolArgument do
  subject(:cop) { described_class.new }

  each_perform_method do
    context 'with symbol argument' do
      it 'registers an offense and corrects' do
        expect_offense(<<~RUBY)
          MyJob.perform(:symbol)
                           ^^^^^^^ Symbols are not Sidekiq-serializable; use strings instead.
        RUBY

        expect_correction(<<~RUBY)
          MyJob.perform('symbol')
        RUBY
      end
    end

    it_behaves_like 'nested unserializable',
      ':symbol',
      'Symbols are not Sidekiq-serializable; use strings instead.',
      correction: "'symbol'"
  end
end
