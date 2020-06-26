RSpec.shared_context('rewrite_performs') do |method|
  def expect_offense(source, file = nil)
    super(rewrite_performs(source, true), file)
  end

  def expect_no_offenses(source, file = nil)
    super(rewrite_performs(source), file)
  end

  def expect_correction(correction)
    super(rewrite_performs(correction))
  end

  define_method(:rewrite_performs) do |source, rewrite_annotations = false|
    size_difference = method.length - 7

    if EachPerformMethod::METHODS_WITH_ARG.include?(method) && (arg = EachPerformMethod::METHOD_ARGS[method])
      source.gsub!(/(?<=\.#{EachPerformMethod::PERFORM_METHOD}\()/, "#{arg}, ")
      size_difference += arg.size + 2
    end

    source.gsub!(/(?<=\s)\^/, "#{(' ' * size_difference)}^") if rewrite_annotations
    source.gsub!(/(?<=\.)#{EachPerformMethod::PERFORM_METHOD}(?=\()/, method.to_s)
  end
  private :rewrite_performs # rubocop:disable Style/AccessModifierDeclarations
end
