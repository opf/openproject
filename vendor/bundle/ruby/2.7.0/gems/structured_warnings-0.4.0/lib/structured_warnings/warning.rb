# This module encapsulates the extensions to Warning, that are introduced
# by this library.
module StructuredWarnings::Warning
  # :call-seq:
  #   warn(message = nil)
  #   warn(warning_class, message)
  #   warn(warning_instance)
  #
  # This method provides a +raise+-like interface. It extends the default
  # warn in ::Warning to allow the use of structured warnings.
  #
  # Internally it uses the StructuredWarnings::warner to format a message
  # based on the given warning class, the message and a stack frame.
  # The return value is passed to super, which is likely the implementation
  # in ::Warning. That way, it is less likely, that structured_warnings
  # interferes with other extensions.
  #
  # If the warner returns nil or an empty string the underlying warn will not
  # be called. That way, warnings may be transferred to other devices without
  # the need to redefine ::Warning#warn.
  #
  # Just like the original version, this method does not take command line
  # switches or verbosity levels into account. In order to deactivate all
  # warnings use <code>StructuredWarnings::Base.disable</code>.
  #
  #   warn "This is an old-style warning" # This will emit a StructuredWarnings::StandardWarning
  #
  #   class Foo
  #     def bar
  #       warn StructuredWarnings::DeprecationWarning, "Never use bar again, use beer"
  #     end
  #     def beer
  #       "Ahhh"
  #     end
  #   end
  #
  #   warn StructuredWarnings::Base.new("The least specific warning you can get")
  #
  def warn(*args)
    first = args.shift
    if first.is_a? Class and first <= StructuredWarnings::Base
      warning = first
      message = args.shift

    elsif first.is_a? StructuredWarnings::Base
      warning = first.class
      message = first.message

    elsif caller.shift.include? 'lib/structured_warnings/kernel.rb'
      warning = StructuredWarnings::StandardWarning
      message = first.to_s

    else
      warning = StructuredWarnings::BuiltInWarning
      message = first.to_s.split(':', 4).last[1..-2]
    end

    options = args.first.is_a?(Hash) ? args.shift : {}

    # If args is not empty, user passed an incompatible set of arguments.
    # Maybe somebody else is overriding warn as well and knows, what to do.
    # Better do nothing in this case. See #5
    return super unless args.empty?

    if warning.active?
      output = StructuredWarnings.warner.format(warning, message, options, caller(1))
      super(output) unless output.nil? or output.to_s.empty?
    end
  end
end

Warning.extend StructuredWarnings::Warning
