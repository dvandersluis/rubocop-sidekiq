RSpec.describe RuboCop::Cop::Sidekiq::ActiveRecordArgument do
  let(:cop_config) { {} }
  let(:config) do
    RuboCop::Config.new('Sidekiq/ActiveRecordArgument' => cop_config)
  end

  subject(:cop) { described_class.new(config) }

  each_perform_method do
    context 'Model.find' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.find(5))
                   #{_______} ^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'Model.all' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.all)
                   #{_______} ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.where(foo: :bar).first)
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain with non-disallowed method' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyWorker.#{perform}(Model.my_scope.last(3))
                   #{_______} ^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR method called as an instance method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyWorker.#{perform}(foo.find)
        RUBY
      end
    end

    context 'AR as argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def finder(query)
            query.first
          end

          MyWorker.#{perform}(finder(Model.all))
                   #{_______}        ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'non-AR as argument' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def finder(query)
            query.first
          end

          MyWorker.#{perform}(finder(Model.first.id))
        RUBY
      end
    end

    context 'AR as kwarg' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def finder(query:)
            query.first
          end

          MyWorker.#{perform}(finder(query: Model.all))
                   #{_______}               ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'non-AR as kwarg' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def finder(id:)
            id.to_s
          end

          MyWorker.#{perform}(finder(id: Model.first.id))
        RUBY
      end
    end
  end

  context 'with DetectLocalIdentifiers: true' do
    let(:cop_config) { { 'DetectLocalIdentifiers' => true } }
    let(:perform) { 'perform_async' }
    let(:_______) { '             ' }

    context 'method call' do
      context 'explicit return' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              return Model.last(5)
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'implicit return' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              Model.last(5)
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'conditional return, AR in condition' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder(x)
              if x
                return Model.last(5)
              end

              true
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'conditional return, AR default' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder(x)
              if x
                return 5
              end

              Model.last(5)
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'returning variable, explicit' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              foo = Model.last(5)
              return foo
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'returning variable, implicit' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              foo = Model.last(5)
              foo
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'returning chained variable, implicit' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              foo = Model.last(5)
              foo.first
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'returning chained variable, explicit' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              foo = Model.last(5)
              return foo.first
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'multiple return' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder
              return Model.last(5), true
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'multiple return, no AR' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def finder
              return :a, :b
            end

            MyWorker.#{perform}(finder)
          RUBY
        end
      end

      context 'AR in body, not returned' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def finder
              model = Model.last
              model.id
            end

            MyWorker.#{perform}(finder)
          RUBY
        end
      end

      context 'multiple AR in body, not returned' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def finder
              model = Model.last
              post = Post.last
              :found
            end

            MyWorker.#{perform}(finder)
          RUBY
        end
      end

      context 'AR as default argument' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder(query = Model.all)
              query.first
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'AR as multiple default arguments' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder(query = Model.all, query2 = Post.all)
              query2
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'AR as default kwarg' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def finder(query: Model.all)
              query.first
            end

            MyWorker.#{perform}(finder)
                     #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'perform in method' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def call
              Model.all
            end

            def perform
              MyWorker.perform_async(call)
                                     ^^^^ ActiveRecord objects are not Sidekiq-serializable.
            end
          RUBY
        end
      end

      context 'perform in method, with self' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def call
              Model.all
            end

            def perform
              MyWorker.perform_async(self.call)
                                     ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            end
          RUBY
        end
      end
    end

    context 'lvar' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          finder = Model.last(5)

          MyWorker.#{perform}(finder)
                   #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end

      context 'method chain ending in AR method' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            finder = Model.where(name: 'test')
            MyWorker.#{perform}(finder.first)
                     #{_______} ^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'method chain ending in non-AR method' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            finder = Model.where(name: 'test')
            MyWorker.#{perform}(finder.id)
          RUBY
        end
      end

      context 'long method chain ending in non-AR method' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            finder = Model.where(name: 'test')
            MyWorker.#{perform}(finder.first.id)
          RUBY
        end
      end
    end

    context 'ivar' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          @finder = Model.last(5)

          MyWorker.#{perform}(@finder)
                   #{_______} ^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'cvar' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          @@finder = Model.last(5)

          MyWorker.#{perform}(@@finder)
                   #{_______} ^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'gvar' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          $finder = Model.last(5)

          MyWorker.#{perform}($finder)
                   #{_______} ^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'constant' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          FINDER = Model.last(5)

          MyWorker.#{perform}(FINDER)
                   #{_______} ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'op-asgn' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          arr = []
          arr += Model.last(5)

          MyWorker.#{perform}(arr)
                   #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'or-asgn' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          arr ||= Model.last(5)

          MyWorker.#{perform}(arr)
                   #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'and-asgn' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          arr &&= Model.last(5)

          MyWorker.#{perform}(arr)
                   #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'multiple assignment' do
      context 'non-AR' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            foo, bar = 1, 2
            MyWorker.#{perform}(bar)
          RUBY
        end
      end

      context 'balanced' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            foo, bar = Model.last(5), 12

            MyWorker.#{perform}(foo)
                     #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'balanced, non AR var' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            foo, bar = Model.last(5), 12

            MyWorker.#{perform}(bar)
          RUBY
        end
      end

      context 'single rhs' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            foo, *bar = Model.last(5)

            MyWorker.#{perform}(foo)
                     #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'single rhs splat' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            foo, *bar = Model.last(5)

            MyWorker.#{perform}(bar)
                     #{_______} ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end
    end

    context 'weird shit', :skip do
      context 'lvar reassignment' do
        it 'does not register an exception' do
          expect_no_offenses(<<~RUBY)
            def my_method(arg = true)
              foo = false
              return foo if arg

              foo = Model.all
              false
            end

            MyWorker.perform_async(my_method)
          RUBY
        end
      end

      context 'method defined after invocation' do
        let(:source) do
          <<~RUBY
            class Foo
              def perform
                MyWorker.perform_async(my_method)
                                       ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
              end

            private

              def my_method
                Model.all
              end
            end
          RUBY
        end

        it 'registers an exception' do
          expect_offense(source)
        end
      end

      context 'reused identifiers' do
        it 'does not register an exception' do
          expect_no_offenses(<<~RUBY)
            def not_used
              Model.all
            end

            def background
              not_used = false
              MyWorker.perform_async(not_used)
            end
          RUBY
        end
      end

      context 'different modules' do
        let(:source) do
          <<~RUBY
            module A
              def call
                Model.all
              end
            end

            module B
              def call
                :B
              end

              def perform
                MyWorker.perform_async(call)
              end
            end
          RUBY
        end

        it 'does not register an offense' do
          expect_no_offenses(source)
        end
      end

      context 'different classes' do
        let(:source) do
          <<~RUBY
            class A
              def call
                Model.all
              end
            end

            class B
              def call
                :B
              end

              def perform
                MyWorker.perform_async(call)
              end
            end
          RUBY
        end

        it 'does not register an offense' do
          expect_no_offenses(source)
        end
      end

      context 'different classes with inheritence' do
        let(:source) do
          <<~RUBY
            class A
              def call
                Model.all
              end
            end

            class B < A
              def perform
                MyWorker.perform_async(call)
                                       ^^^^ ActiveRecord objects are not Sidekiq-serializable.
              end
            end
          RUBY
        end

        it 'registers an offense' do
          expect_offense(source)
        end
      end
    end
  end
end
