require "cell/testing"

module Cell
  # Test your cells.
  #
  # TODO: document me, Capybara, etc.
  class TestCase < ActiveSupport::TestCase
    include Testing
  end
end

Cell::Testing.capybara = true if Object.const_defined?(:"Capybara")
