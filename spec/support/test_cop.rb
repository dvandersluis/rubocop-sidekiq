module Test
  class Cop < RuboCop::Cop::Cop
    include RuboCop::Cop::Sidekiq::Helpers
  end

  class UnserializableCop < RuboCop::Cop::Cop
    include RuboCop::Cop::Sidekiq::Helpers
    include RuboCop::Cop::Sidekiq::UnserializableArgument

    # For the purpose of this test any symbol is unserializable
    def_node_matcher :unserializable?, <<~PATTERN
      (sym _)
    PATTERN
  end
end
