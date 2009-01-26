require File.dirname(__FILE__) + '/../test_helper'
require 'issue_relations_controller'

# Re-raise errors caught by the controller.
class IssueRelationsController; def rescue_action(e) raise e end; end


class IssueRelationsControllerTest < Test::Unit::TestCase
  def test_new_routing
    assert_routing(
      {:method => :post, :path => '/issues/1/relations'},
      {:controller => 'issue_relations', :action => 'new', :issue_id => '1'}
    )
  end
  
  def test_destroy_routing
    assert_recognizes( #TODO: use DELETE on issue URI
      {:controller => 'issue_relations', :action => 'destroy', :issue_id => '1', :id => '23'},
      {:method => :post, :path => '/issues/1/relations/23/destroy'}
    )
  end
end
