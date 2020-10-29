require 'structured_warnings/test'

Minitest::Test.class_eval do
  include StructuredWarnings::Test::Assertions
end
