# This warner is used in Assertions#assert_warn and
# Assertions#assert_no_warn blocks. It captures all warnings in format and
# provides access to them using the warned? method.
class StructuredWarnings::Test::Warner < StructuredWarnings::Warner
  # Overrides the public interface of StructuredWarnings::Warner. This
  # method always returns nil to avoid warnings on stdout during assert_warn
  # and assert_no_warn blocks.
  def format(warning, message, options, call_stack)
    given_warnings << warning.new(message)
    nil
  end

  # Returns true if any warning or a subclass of warning was emitted.
  def warned?(warning, message = nil)
    case message
    when Regexp
      given_warnings.any? {|w| w.is_a?(warning) && w.message =~ message}
    when String
      given_warnings.any? {|w| w.is_a?(warning) && w.message == message}
    when nil
      given_warnings.any? {|w| w.is_a?(warning)}
    else
      raise ArgumentError, "Unkown argument type for 'message': #{message.class.inspect}"
    end
  end

  # :stopdoc:
  protected

  # Returns an array of all warning classes, that were given to this
  # warner's format method, including duplications.
  def given_warnings
    @given_warnings ||= []
  end
  # :startdoc:
end
