require File.dirname(__FILE__) + '/../test_helper'
require 'members_controller'

# Re-raise errors caught by the controller.
class MembersController; def rescue_action(e) raise e end; end


class MembersControllerTest < Test::Unit::TestCase
  def test_members_routing
    assert_routing(
      {:method => :post, :path => 'projects/5234/members/new'},
      :controller => 'members', :action => 'new', :id => '5234'
    )
  end
end
