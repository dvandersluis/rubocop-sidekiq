module Test
  class Cop < RuboCop::Cop::Cop
    include RuboCop::Cop::Sidekiq::Helpers
  end
end
