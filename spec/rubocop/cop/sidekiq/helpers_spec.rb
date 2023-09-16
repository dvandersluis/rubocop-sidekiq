RSpec.describe RuboCop::Cop::Sidekiq::Helpers do
  let(:cop) { Test::Cop.new }

  describe '#sidekiq_job?' do
    let(:node) { parse_source(source).ast }

    subject { cop.sidekiq_job?(node) }

    context 'class including Sidekiq::Job' do
      let(:source) do
        <<~RUBY
          class MyJob
            include Sidekiq::Job
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end

    context 'class not including Sidekiq::Job' do
      let(:source) do
        <<~RUBY
          class MyJob
          end
        RUBY
      end

      it { is_expected.to be_nil }
    end

    context 'include is not the first statement' do
      let(:source) do
        <<~RUBY
          class MyJob
            FOO = :foo

            def call
              FOO
            end

            include Sidekiq::Job
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end

    context 'class containing a job' do
      let(:source) do
        <<~RUBY
          class Outer
            class Inner
              def foo
              end

              include Sidekiq::Job
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
            include Sidekiq::Job
          end
        RUBY
      end

      it { is_expected.to be(true) }
    end
  end

  describe '#in_sidekiq_job?' do
    let(:ast) { parse_source(source).ast }
    let(:node) { ast.each_descendant(:def).first }

    subject { cop.in_sidekiq_job?(node) }

    context 'node is inside a class job' do
      let(:source) do
        <<~RUBY
          class MyJob
            include Sidekiq::Job

            def perform
            end
          end
        RUBY
      end

      it 'returns the full job node' do
        expect(subject).to eq(ast)
      end
    end

    context 'node is inside an anonymous job' do
      let(:source) do
        <<~RUBY
          Class.new do
            include Sidekiq::Job

            def perform
            end
          end
        RUBY
      end

      it 'returns the full job node' do
        expect(subject).to eq(ast)
      end
    end

    context 'node is inside a class that is not a job' do
      let(:source) do
        <<~RUBY
          class Foo
            def perform
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'node is inside an anonymous non-job' do
      let(:source) do
        <<~RUBY
          Class.new do
            def perform
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'node is inside another scope' do
      let(:source) do
        <<~RUBY
          module Foo
            def perform
            end
          end
        RUBY
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
