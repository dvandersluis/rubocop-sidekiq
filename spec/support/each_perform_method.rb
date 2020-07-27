module EachPerformMethod
  PERFORM_METHOD = 'perform'.freeze
  METHODS = %i(perform_async perform_in perform_at).freeze
  METHODS_WITH_ARG = %i(perform_in perform_at).freeze
  METHOD_ARGS = {
    perform_in: '1.hour',
    perform_at: '1.minute.from_now'
  }.freeze

  def each_perform_method(methods: METHODS, rewrite_mode: :push, &block)
    methods.each do |method|
      context "##{method}" do
        include_context 'rewrite_performs', method, rewrite_mode
        instance_exec(&block)
      end
    end
  end
end
