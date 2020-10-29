require 'structured_warnings/version'

# Compatibility layer
require 'warning' unless defined? ::Warning

require 'dynamic'

module StructuredWarnings
  # If you <code>require 'test/unit'</code> after +structured_warnings+ you
  # have to <code>require 'structured_warnings/test'</code> manually,
  # otherwise the test extensions will be added automatically.
  module ClassMethods
    # Executes a block using the given warner. This may be used to suppress
    # warnings to stdout, but fetch them and redirect them to somewhere else.
    #
    # This behaviour is used in the StructuredWarnings::Assertions
    def with_warner(warner)
      Dynamic.let(:warner => warner) do
        yield
      end
    end

    # Gives access to the currently used warner. Default is an instance of
    # StructuredWarnings::Warner
    def warner
      Dynamic[:warner]
    end

    #:stopdoc:
    # Sets a new warner
    def warner=(new_warner)
      Dynamic[:warner] = new_warner
    end

    # returns an Array of all currently disabled warnings.
    #
    # *Note*: Everyday users are supposed to use the methods in
    # Warning::ClassMethods
    def disabled_warnings
      Dynamic[:disabled_warnings]
    end

    # sets an array of all currently disabled warnings. It is expected that this
    # array consists only of the Warning class and its subclasses.
    #
    # *Note*: Everyday users are supposed to use the methods in
    # Warning::ClassMethods
    def disabled_warnings=(new_disabled_warnings)
      Dynamic[:disabled_warnings] = new_disabled_warnings
    end

    # Executes a block with the given set of disabled instances.
    #
    # *Note*: Everyday users are supposed to use the methods in
    # Warning::ClassMethods
    def with_disabled_warnings(disabled_warnings)
      Dynamic.let(:disabled_warnings => disabled_warnings) do
        yield
      end
    end
    #:startdoc:
  end

  extend ClassMethods
end

require 'structured_warnings/kernel'
require 'structured_warnings/warning'
require 'structured_warnings/warner'
require 'structured_warnings/base'


unless Dynamic.variables.key? :disabled_warnings
  StructuredWarnings::disabled_warnings = []
  StructuredWarnings::warner = StructuredWarnings::Warner.new
end

require 'structured_warnings/minitest' if defined? Minitest::Test
require 'structured_warnings/test_unit' if defined? Test::Unit::TestCase
