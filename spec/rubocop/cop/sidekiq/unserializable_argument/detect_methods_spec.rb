RSpec.describe RuboCop::Cop::Sidekiq::UnserializableArgument::DetectMethods, :include_ast do
  let(:cop) { Test::UnserializableCop.new }
  let(:processed_source) { parse_source(source) }

  subject { described_class.new(cop).call(processed_source.ast) }

  describe '#call' do
    context 'returning unserializable' do
      context 'implicit return' do
        let(:source) do
          <<~RUBY
            def my_method
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'explicit return' do
        let(:source) do
          <<~RUBY
            def my_method
              return :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'implicit return with other lines' do
        let(:source) do
          <<~RUBY
            def my_method
              do_something
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'explicit return with other lines' do
        let(:source) do
          <<~RUBY
            def my_method
              do_something
              return :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'conditional return, conditional case' do
        let(:source) do
          <<~RUBY
            def my_method(condition)
              return :symbol if condition
              false
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'conditional return, default case' do
        let(:source) do
          <<~RUBY
            def my_method(condition)
              return false if condition
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'multiple return' do
        let(:source) do
          <<~RUBY
            def my_method
              return :symbol, other_method, false
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol), s(:send, nil, :other_method)]
          )
        end
      end

      context 'array return' do
        let(:source) do
          <<~RUBY
            def my_method
              return [:symbol, other_method, false]
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol), s(:send, nil, :other_method)]
          )
        end
      end

      context 'hash return' do
        let(:source) do
          <<~RUBY
            def my_method
              return { one: :symbol, two: other_method, three: false }
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol), s(:send, nil, :other_method)]
          )
        end
      end

      context 'method chain' do
        let(:source) do
          <<~RUBY
            def returns_symbol
              :symbol
            end

            def my_method
              returns_symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:send, nil, :returns_symbol)],
            s(:send, nil, :returns_symbol) => [s(:sym, :symbol)]
          )
        end
      end

      context 'method chain with args' do
        let(:source) do
          <<~RUBY
            def returns_symbol(foo)
              :symbol
            end

            def my_method
              returns_symbol(7)
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:send, nil, :returns_symbol)],
            s(:send, nil, :returns_symbol) => [s(:sym, :symbol)]
          )
        end
      end

      context 'default argument' do
        let(:source) do
          <<~RUBY
            def my_method(ret = :symbol)
              ret
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:lvar, :ret)]
          )
        end
      end

      context 'define_method' do
        let(:source) do
          <<~RUBY
            define_method(:my_method) do
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'singleton method' do
        let(:source) do
          <<~RUBY
            def self.my_method
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, s(:self), :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'define_method with receiver' do
        let(:source) do
          <<~RUBY
            MyClass.define_method(:my_method) do
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, s(:const, nil, :MyClass), :my_method) => [s(:sym, :symbol)]
          )
        end
      end

      context 'def with receiver' do
        let(:source) do
          <<~RUBY
            def MyClass.my_method
              :symbol
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, s(:const, nil, :MyClass), :my_method) => [s(:sym, :symbol)]
          )
        end
      end
    end

    context 'returning serializable' do
      context 'void return' do
        let(:source) do
          <<~RUBY
            def my_method
            end
          RUBY
        end

        it 'does not add the method' do
          expect(subject).to be_empty
        end
      end

      context 'implicit return' do
        let(:source) do
          <<~RUBY
            def my_method
              5
            end
          RUBY
        end

        it 'does not add the method' do
          expect(subject).to be_empty
        end
      end

      context 'explicit return' do
        let(:source) do
          <<~RUBY
            def my_method
              return 5
            end
          RUBY
        end

        it 'does not add the method' do
          expect(subject).to be_empty
        end
      end

      context 'define_method' do
        let(:source) do
          <<~RUBY
            define_method(:my_method) do
              5
            end
          RUBY
        end

        it 'does not add the method' do
          expect(subject).to be_empty
        end
      end
    end

    context 'potentially unserializable' do
      context 'unserializable in method chain' do
        let(:source) do
          <<~RUBY
            def my_method
              :symbol.to_s
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:send, s(:sym, :symbol), :to_s)]
          )
        end
      end

      context 'unknown method call' do
        let(:source) do
          <<~RUBY
            def my_method
              do_something
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:send, nil, :do_something)]
          )
        end
      end

      context 'define_method with default value' do
        let(:source) do
          <<~RUBY
            define_method(:my_method) do |ret = 5|
              ret
            end
          RUBY
        end

        it 'adds the method' do
          expect(subject).to eq(
            s(:send, nil, :my_method) => [s(:lvar, :ret)]
          )
        end
      end
    end

    context 'multiple definitions' do
      let(:source) do
        <<~RUBY
          def method_with_no_return
          end

          def method_with_serializable_return
            5
          end

          def method_with_unserializable_return
            :symbol
          end
        RUBY
      end

      it 'adds only unserializable returns' do
        expect(subject).to eq(
          s(:send, nil, :method_with_unserializable_return) => [s(:sym, :symbol)]
        )
      end
    end

    context 'no definitions' do
      let(:source) do
        <<~RUBY
        RUBY
      end

      it 'is empty' do
        expect(subject).to be_empty
      end
    end
  end
end
