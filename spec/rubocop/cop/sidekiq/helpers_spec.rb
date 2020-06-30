RSpec.describe RuboCop::Cop::Sidekiq::Helpers do
  let(:cop) { Test::Cop.new }

  describe '#sidekiq_worker?' do
    let(:node) { parse_source(source).ast }

    subject { cop.sidekiq_worker?(node) }

    context 'class including Sidekiq::Worker' do
      let(:source) do
        <<~RUBY
          class MyWorker
            include Sidekiq::Worker
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end

    context 'class not including Sidekiq::Worker' do
      let(:source) do
        <<~RUBY
          class MyWorker
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'include is not the first statement' do
      let(:source) do
        <<~RUBY
          class MyWorker
            FOO = :foo

            def call
              FOO
            end

            include Sidekiq::Worker
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end

    context 'class containing a worker' do
      let(:source) do
        <<~RUBY
          class Outer
            class Inner
              def foo
              end

              include Sidekiq::Worker
            end
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'anonymous class' do
      let(:source) do
        <<~RUBY
          Class.new do
            include Sidekiq::Worker
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end
  end
end
