# Descendents of class StructuredWarnings::Base are used to  raise structured
# warnings. They enable programmers to explicitly supress certain kinds of
# warnings and provide additional information in contrast to the plain warn
# method. They implement an Exception-like interface and carry information about
# the warning -- its type (the warning's class name), an optional descriptive
# string, and optional traceback information. Programs may subclass
# StructuredWarnings::Base to add additional information.
#
# Large portions of this class's documentation are taken from the Exception
# RDoc.
class StructuredWarnings::Base
  # Construct a new StructuredWarning::Base object, optionally passing in a
  # message.
  def initialize(message = nil)
    @message = message
    @backtrace = caller(1)
  end


  # call-seq:
  #    warning.backtrace    => array
  #
  # Returns any backtrace associated with the warning. The backtrace
  # is an array of strings, each containing either ``filename:lineNo: in
  # `method''' or ``filename:lineNo.''
  def backtrace
    @backtrace
  end

  # Sets the backtrace information associated with warning. The argument must
  # be an array of String objects in the format described in
  # Exception#backtrace.
  def set_backtrace(backtrace)
    @backtrace = backtrace
  end

  # Returns warning's message (or the name of the warning if no message is set).
  def to_s
    @message || self.class.name
  end
  alias_method :to_str, :to_s
  alias_method :message, :to_s

  # Return this warning's class name and message
  def inspect
    "#<#{self.class}: #{self}>"
  end

  # This module extends StructuredWarnings::Base and each subclass. It may be
  # used to activate or deactivate a set of warnings.
  module ClassMethods
    # returns a Boolean, stating whether a warning of this type would be
    # emmitted or not.
    def active?
      StructuredWarnings::disabled_warnings.all? {|w| !(w >= self)}
    end

    # call-seq:
    #   disable()
    #   disable() {...}
    #
    # If called without a block, warnings of this type will be disabled in the
    # current thread and all new child threads.
    #
    #   warn("this will be printed") # creates a StructuredWarnings::StandardWarning
    #                                # which is enabled by default
    #
    #   StructuredWarnings::Base.disable
    #
    #   warn("this will not be printed") # creates a StructuredWarnings::StandardWarning
    #                                    # which is currently disabled
    #
    # If called with a block, warnings of this type will be disabled in the
    # dynamic scope of the given block.
    #
    #   StructuredWarnings::Base.disable do
    #     warn("this will not be printed") # creates a StructuredWarnings::StandardWarning
    #                                      # which is currently disabled
    #   end
    #
    #   warn("this will be printed") # creates a StructuredWarnings::StandardWarning
    #                                # which is currently enabled
    def disable
      if block_given?
        StructuredWarnings::with_disabled_warnings(StructuredWarnings.disabled_warnings | [self]) do
          yield
        end
      else
        StructuredWarnings::disabled_warnings |= [self]
      end
    end

    # call-seq:
    #   enable()
    #   enable() {...}
    #
    # This method has the same semantics as disable, only with the opposite
    # outcome. In general the last assignment wins, so that disabled warnings
    # may be enabled again and so on.
    def enable
      if block_given?
        StructuredWarnings::with_disabled_warnings(StructuredWarnings.disabled_warnings - [self]) do
          yield
        end
      else
        StructuredWarnings::disabled_warnings -= [self]
      end
    end
  end

  extend ClassMethods
end

# This warning is used when calling #Kernel.warn without arguments.
class StructuredWarnings::StandardWarning < StructuredWarnings::Base; end

# This is a general warning used to mark certain actions as deprecated. We
# recommend to add a useful warning message, which alternative to use instead.
class StructuredWarnings::DeprecationWarning < StructuredWarnings::Base; end

# This warning marks single methods as deprecated. We
# recommend to add a useful warning message, which alternative to use instead.
class StructuredWarnings::DeprecatedMethodWarning < StructuredWarnings::DeprecationWarning; end

# This warning marks the given parameters for a certain methods as
# deprecated. We recommend to add a useful warning message, which
# alternative to use instead.
class StructuredWarnings::DeprecatedSignatureWarning < StructuredWarnings::DeprecationWarning; end

# This warning is used for Ruby's built in warnings about accessing unused
# instance vars, redefining constants, etc.
class StructuredWarnings::BuiltInWarning < StructuredWarnings::Base; end
