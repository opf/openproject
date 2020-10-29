# This module ecapsulates all extensions to support <code>test/unit</code>.
module StructuredWarnings::Test::Assertions
  # :call-seq:
  #   assert_no_warn(message = nil) {|| ...}
  #   assert_no_warn(warning_class, message) {|| ...}
  #   assert_no_warn(warning_instance) {|| ...}
  #
  # Asserts that the given warning was not emmitted. It may be restricted
  # to a certain subtree of warnings and/or message.
  #
  #   def foo
  #     warn StructuredWarnings::DeprecatedMethodWarning, 'used foo, use bar instead'
  #     bar
  #   end
  #
  #   assert_no_warn(StructuredWarnings::StandardWarning) { foo }    # passes
  #
  #   assert_no_warn(StructuredWarnings::DeprecationWarning) { foo } # fails
  #   assert_no_warn() { foo }                                       # fails
  #
  # See assert_warn for more examples.
  #
  # *Note*: It is currently not possible to add a custom failure message.
  def assert_no_warn(*args)
    warning, message = parse_arguments(args)

    w = StructuredWarnings::Test::Warner.new
    StructuredWarnings::with_warner(w) do
      yield
    end

    assert_equal(false, w.warned?(warning, message), "<#{args_inspect(args)}> has been emitted.")
  end

  # :call-seq:
  #   assert_warn(message = nil) {|| ...}
  #   assert_warn(warning_class, message) {|| ...}
  #   assert_warn(warning_instance) {|| ...}
  #
  # Asserts that the given warning was emmitted. It may be restricted to a
  # certain subtree of warnings and/or message.
  #
  #   def foo
  #     warn StructuredWarnings::DeprecatedMethodWarning, 'used foo, use bar instead'
  #     bar
  #   end
  #
  #   # passes
  #   assert_warn(StructuredWarnings::DeprecatedMethodWarning) { foo }
  #   assert_warn(StructuredWarnings::DeprecationWarning) { foo }
  #   assert_warn() { foo }
  #   assert_warn(StructuredWarnings::Base, 'used foo, use bar instead') { foo }
  #   assert_warn(StructuredWarnings::Base, /use bar/) { foo }
  #   assert_warn(StructuredWarnings::Base.new('used foo, use bar instead')) { foo }
  #
  #   # fails
  #   assert_warn(StructuredWarnings::StandardWarning) { foo }
  #   assert_warn(StructuredWarnings::Base, /deprecated/) { foo }
  #   assert_warn(StructuredWarnings::Base.new) { foo }
  #
  # *Note*: It is currently not possible to add a custom failure message.
  def assert_warn(*args)
    warning, message = parse_arguments(args)

    w = StructuredWarnings::Test::Warner.new
    StructuredWarnings::with_warner(w) do
      yield
    end

    assert_equal(true, w.warned?(warning, message), "<#{args_inspect(args)}> has not been emitted.")
  end

  private

  def parse_arguments(args)
    args = args.clone
    first = args.shift
    if first.is_a? Class and first <= StructuredWarnings::Base
      warning = first
      message = args.shift

    elsif first.is_a? StructuredWarnings::Base
      warning = first.class
      message = first.message

    elsif first.is_a? String
      warning = StructuredWarnings::StandardWarning
      message = first

    else
      warning = StructuredWarnings::Base
      message = nil
    end

    unless args.empty?
      raise ArgumentError,
            "wrong number of arguments (#{args.size + 2} for 2)"
    end

    return warning, message
  end

  def args_inspect(args)
    args.map { |a| a.inspect }.join(', ')
  end
end
