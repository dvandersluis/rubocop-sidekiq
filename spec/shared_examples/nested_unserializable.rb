RSpec.shared_examples 'nested unserializable' do |argument, msg, correction: nil|
  test_statement = correction ? 'registers an offense and corrects' : 'registers an offense'

  context 'symbol in array' do
    it test_statement do
      expect_offense(<<~RUBY)
        MyWorker.perform([#{argument}])
                          #{'^' * argument.length} #{msg}
      RUBY

      expect_correction(<<~RUBY) if correction
        MyWorker.perform([#{correction}])
      RUBY
    end
  end

  context 'symbol in nested array' do
    it test_statement do
      expect_offense(<<~RUBY)
        MyWorker.perform([[#{argument}]])
                           #{'^' * argument.length} #{msg}
      RUBY

      expect_correction(<<~RUBY) if correction
        MyWorker.perform([[#{correction}]])
      RUBY
    end
  end

  context 'symbol in hash' do
    it test_statement do
      expect_offense(<<~RUBY)
        MyWorker.perform(name: #{argument})
                               #{'^' * argument.length} #{msg}
      RUBY

      expect_correction(<<~RUBY) if correction
        MyWorker.perform(name: #{correction})
      RUBY
    end
  end

  context 'symbol in nested hash' do
    it test_statement do
      expect_offense(<<~RUBY)
        MyWorker.perform(data: { name: #{argument} })
                                       #{'^' * argument.length} #{msg}
      RUBY

      expect_correction(<<~RUBY) if correction
        MyWorker.perform(data: { name: #{correction} })
      RUBY
    end
  end

  context 'symbol in nested mess' do
    it test_statement do
      expect_offense(<<~RUBY)
        MyWorker.perform(data: [{ name: #{argument}, type: #{argument} }])
                                        #{'^' * argument.length} #{msg}
                                        #{' ' * argument.length}        #{'^' * argument.length} #{msg}
      RUBY

      expect_correction(<<~RUBY) if correction
        MyWorker.perform(data: [{ name: #{correction}, type: #{correction} }])
      RUBY
    end
  end
end
