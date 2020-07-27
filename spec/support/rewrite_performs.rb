RSpec.shared_context('rewrite_performs') do |method, rewrite_mode = :push|
  def expect_offense(source, file = nil)
    super(rewrite_performs(source, true), file)
  end

  def expect_no_offenses(source, file = nil)
    super(rewrite_performs(source), file)
  end

  def expect_correction(correction)
    super(rewrite_performs(correction))
  end

  def rewrite_annotations(method, source, rewrite_mode)
    if rewrite_mode == :push
      push_annotations(method, source)
    elsif rewrite_mode == :extend
      extend_annotations(method, source)
    end
  end

  def push_annotations(method, source)
    size_difference = method.length - 7

    if EachPerformMethod::METHODS_WITH_ARG.include?(method) && (arg = EachPerformMethod::METHOD_ARGS[method])
      size_difference += arg.size + 2
    end

    source.gsub!(/(?<=\s)\^/, "#{(' ' * size_difference)}^")
  end

  def extend_annotations(method, source)
    size_difference = method.length - EachPerformMethod::PERFORM_METHOD.length
    source.gsub!(/(?<=\s)\^/, "#{('^' * size_difference)}^")
  end

  define_method(:rewrite_performs) do |source, annotations = false|
    if EachPerformMethod::METHODS_WITH_ARG.include?(method) && (arg = EachPerformMethod::METHOD_ARGS[method])
      source.gsub!(/(?<=\.#{EachPerformMethod::PERFORM_METHOD}\()/, "#{arg}, ")
    end

    source = rewrite_annotations(method, source, rewrite_mode) if annotations
    source.gsub!(/(?<=\.)#{EachPerformMethod::PERFORM_METHOD}(?=\(|\b)/, method.to_s) || source
  end
  private :rewrite_performs # rubocop:disable Style/AccessModifierDeclarations
end
