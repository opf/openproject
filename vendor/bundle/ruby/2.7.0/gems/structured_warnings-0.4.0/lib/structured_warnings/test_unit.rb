require 'structured_warnings/test'

Test::Unit::TestCase.class_eval do
  include StructuredWarnings::Test::Assertions
end
