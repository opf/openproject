require File.dirname(__FILE__) + '/../test_helper'
require 'help_controller'

# Re-raise errors caught by the controller.
class HelpController; def rescue_action(e) raise e end; end

class HelpControllerTest < Test::Unit::TestCase
  def setup
    @controller = HelpController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
