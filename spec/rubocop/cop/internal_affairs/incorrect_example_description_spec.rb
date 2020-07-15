require 'rubocop/cop/internal_affairs/incorrect_example_description'

# rubocop:disable RSpec/ExampleLength
RSpec.describe RuboCop::Cop::InternalAffairs::IncorrectExampleDescription do
  let(:config) do
    RuboCop::Config.new('InternalAffairs/IncorrectExampleDescription' => cop_config)
  end
  let(:cop_config) { {} }

  subject(:cop) { described_class.new(config) }

  context 'wrong description for expects_offense' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        it 'does not register an offense' do
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use an appropriate example description for expect_offense.
          expect_offense(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'registers an offense' do
          expect_offense(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'wrong description and other args for expects_offense' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        it 'does not register an offense', focus: true do
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use an appropriate example description for expect_offense.
          expect_offense(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'registers an offense', focus: true do
          expect_offense(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'no description for expects_offense' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        it do
        ^^ Use an appropriate example description for expect_offense.
          expect_offense(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'registers an offense' do
          expect_offense(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'no description and other args for expects_offense' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        it focus: true do
        ^^ Use an appropriate example description for expect_offense.
          expect_offense(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'registers an offense', focus: true do
          expect_offense(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'right description for expects_offense' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'registers an offense' do
          expect_offense(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'wrong description for expects_no_offenses' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        it 'registers an offense' do
           ^^^^^^^^^^^^^^^^^^^^^^ Use an appropriate example description for expect_no_offenses.
          expect_no_offenses(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'does not register an offense' do
          expect_no_offenses(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'no description for expects_no_offenses' do
    it 'does not register an offense' do
      expect_offense(<<~RUBY)
        it do
        ^^ Use an appropriate example description for expect_no_offenses.
          expect_no_offenses(<<~STRING)
          STRING
        end
      RUBY

      expect_correction(<<~RUBY)
        it 'does not register an offense' do
          expect_no_offenses(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'right description for expects_no_offenses' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'does not register an offense' do
          expect_no_offenses(<<~STRING)
          STRING
        end
      RUBY
    end
  end

  context 'Strict' do
    context 'true' do
      let(:cop_config) { { 'Strict' => true } }

      context 'similar description for expect_offense' do
        it 'registers an offense and corrects' do
          expect_offense(<<~RUBY)
            it 'registers at least one offense' do
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use an appropriate example description for expect_offense.
              expect_offense(<<~STRING)
              STRING
            end
          RUBY

          expect_correction(<<~RUBY)
            it 'registers an offense' do
              expect_offense(<<~STRING)
              STRING
            end
          RUBY
        end
      end

      context 'similar description for expect_no_offenses' do
        it 'registers an offense and corrects' do
          expect_offense(<<~RUBY)
            it 'does not register' do
               ^^^^^^^^^^^^^^^^^^^ Use an appropriate example description for expect_no_offenses.
              expect_no_offenses(<<~STRING)
              STRING
            end
          RUBY

          expect_correction(<<~RUBY)
            it 'does not register an offense' do
              expect_no_offenses(<<~STRING)
              STRING
            end
          RUBY
        end
      end
    end

    context 'false' do
      let(:cop_config) { { 'Strict' => false } }

      context 'similar description for expect_offense' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            it 'registers at least one offense' do
              expect_offense(<<~STRING)
              STRING
            end
          RUBY
        end
      end

      context 'similar description for expect_no_offenses' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            it 'does not register' do
              expect_no_offenses(<<~STRING)
              STRING
            end
          RUBY
        end
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
