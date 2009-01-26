require File.dirname(__FILE__) + '/../test_helper'
require 'reports_controller'

# Re-raise errors caught by the controller.
class ReportsController; def rescue_action(e) raise e end; end


class ReportsControllerTest < Test::Unit::TestCase
  def test_issue_report_routing
    assert_routing(
      {:method => :get, :path => '/projects/567/issues/report'},
      :controller => 'reports', :action => 'issue_report', :id => '567'
    )
    assert_routing(
      {:method => :get, :path => '/projects/567/issues/report/assigned_to'},
      :controller => 'reports', :action => 'issue_report', :id => '567', :detail => 'assigned_to'
    )
    
  end
end
