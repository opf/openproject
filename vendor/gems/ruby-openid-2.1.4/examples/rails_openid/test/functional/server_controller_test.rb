require File.dirname(__FILE__) + '/../test_helper'
require 'server_controller'

# Re-raise errors caught by the controller.
class ServerController; def rescue_action(e) raise e end; end

class ServerControllerTest < Test::Unit::TestCase
  def setup
    @controller = ServerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
