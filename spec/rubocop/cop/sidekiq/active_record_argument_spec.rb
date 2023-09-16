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
          MyJob.perform(Model.find(5))
                           ^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'Model.all' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyJob.perform(Model.all)
                           ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyJob.perform(Model.where(foo: :bar).first)
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR chain with non-disallowed method' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          MyJob.perform(Model.my_scope.last(3))
                           ^^^^^^^^^^^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'AR method called as an instance method' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          MyJob.perform(foo.find)
        RUBY
      end
    end

    context 'AR as argument' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def finder(query)
            query.first
          end

          MyJob.perform(finder(Model.all))
                                  ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'non-AR as argument' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def finder(query)
            query.first
          end

          MyJob.perform(finder(Model.first.id))
        RUBY
      end
    end

    context 'AR as kwarg' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          def finder(query:)
            query.first
          end

          MyJob.perform(finder(query: Model.all))
                                         ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
        RUBY
      end
    end

    context 'non-AR as kwarg' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def finder(id:)
            id.to_s
          end

          MyJob.perform(finder(id: Model.first.id))
        RUBY
      end
    end

    context 'with DetectLocalIdentifiers: true' do
      let(:cop_config) { { 'DetectLocalIdentifiers' => true } }

      context 'method call' do
        context 'explicit return' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder
                return Model.last(5)
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'implicit return' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder
                Model.last(5)
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'multiple return' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder
                return Model.last(5), true
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'multiple return, no AR' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def finder
                return :a, :b
              end

              MyJob.perform(finder)
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

              MyJob.perform(finder)
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

              MyJob.perform(finder)
            RUBY
          end
        end

        context 'AR as default argument' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder(query = Model.all)
                query.first
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'AR as multiple default arguments' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder(query = Model.all, query2 = Post.all)
                query2
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'AR as default kwarg' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              def finder(query: Model.all)
                query.first
              end

              MyJob.perform(finder)
                               ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
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
                MyJob.perform(call)
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
                MyJob.perform(self.call)
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

            MyJob.perform(finder)
                             ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end

        context 'method chain ending in AR method' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              finder = Model.where(name: 'test')
              MyJob.perform(finder.first)
                               ^^^^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'method chain ending in non-AR method' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              finder = Model.where(name: 'test')
              MyJob.perform(finder.id)
            RUBY
          end
        end

        context 'long method chain ending in non-AR method' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              finder = Model.where(name: 'test')
              MyJob.perform(finder.first.id)
            RUBY
          end
        end
      end

      context 'ivar' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            @finder = Model.last(5)

            MyJob.perform(@finder)
                             ^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end

        context 'with instance_variable_set' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              instance_variable_set(:@finder, Model.last(5))

              MyJob.perform(@finder)
                               ^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end
      end

      context 'cvar' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            @@finder = Model.last(5)

            MyJob.perform(@@finder)
                             ^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end

        context 'with class_variable_set' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              class_variable_set(:@@finder, Model.last(5))

              MyJob.perform(@@finder)
                               ^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end
      end

      context 'gvar' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            $finder = Model.last(5)

            MyJob.perform($finder)
                             ^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'constant' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            FINDER = Model.last(5)

            MyJob.perform(FINDER)
                             ^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'op-asgn' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            arr = []
            arr += Model.last(5)

            MyJob.perform(arr)
                             ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'or-asgn' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            arr ||= Model.last(5)

            MyJob.perform(arr)
                             ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'and-asgn' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            arr &&= Model.last(5)

            MyJob.perform(arr)
                             ^^^ ActiveRecord objects are not Sidekiq-serializable.
          RUBY
        end
      end

      context 'multiple assignment' do
        context 'non-AR' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              foo, bar = 1, 2
              MyJob.perform(bar)
            RUBY
          end
        end

        context 'balanced' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              foo, bar = Model.last(5), 12

              MyJob.perform(foo)
                               ^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'balanced, non AR var' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              foo, bar = Model.last(5), 12

              MyJob.perform(bar)
            RUBY
          end
        end

        context 'single rhs' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              foo, *bar = Model.last(5)

              MyJob.perform(foo)
                               ^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end

        context 'single rhs splat' do
          it 'registers an offense' do
            expect_offense(<<~RUBY)
              foo, *bar = Model.last(5)

              MyJob.perform(bar)
                               ^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end
        end
      end

      context 'weird shit', :skip do
        context 'lvar reassignment' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def my_method(arg = true)
                foo = false
                return foo if arg

                foo = Model.all
                false
              end

              MyJob.perform(my_method)
            RUBY
          end
        end

        context 'method defined after invocation' do
          let(:source) do
            <<~RUBY
              class Foo
                def perform
                  MyJob.perform(my_method)
                                   ^^^^^^^^^ ActiveRecord objects are not Sidekiq-serializable.
                end

              private

                def my_method
                  Model.all
                end
              end
            RUBY
          end

          it 'registers an offense' do
            expect_offense(source)
          end
        end

        context 'reused identifiers' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              def not_used
                Model.all
              end

              def background
                not_used = false
                MyJob.perform(not_used)
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
                  MyJob.perform(call)
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
                  MyJob.perform(call)
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
                  MyJob.perform(call)
                                   ^^^^ ActiveRecord objects are not Sidekiq-serializable.
                end
              end
            RUBY
          end

          it 'registers an offense' do
            expect_offense(source)
          end
        end

        context 'nested AR in method' do
          let(:source) do
            <<~RUBY
              def call
                [Model.first, Model.last]
              end

              MyJob.perform(call)
                               ^^^^ ActiveRecord objects are not Sidekiq-serializable.
            RUBY
          end

          it 'registers an offense' do
            expect_offense(source)
          end
        end
      end
    end

    it_behaves_like 'nested unserializable', 'Model.last', 'ActiveRecord objects are not Sidekiq-serializable.'
  end
end
