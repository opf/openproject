# redMine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require "test_helper"

class RoutingTest < ActionController::IntegrationTest
  context "issues" do
    # REST actions
    should_route :get, "/issues", :controller => 'issues', :action => 'index'
    should_route :get, "/issues.pdf", :controller => 'issues', :action => 'index', :format => 'pdf'
    should_route :get, "/issues.atom", :controller => 'issues', :action => 'index', :format => 'atom'
    should_route :get, "/issues.xml", :controller => 'issues', :action => 'index', :format => 'xml'
    should_route :get, "/projects/23/issues", :controller => 'issues', :action => 'index', :project_id => '23'
    should_route :get, "/projects/23/issues.pdf", :controller => 'issues', :action => 'index', :project_id => '23', :format => 'pdf'
    should_route :get, "/projects/23/issues.atom", :controller => 'issues', :action => 'index', :project_id => '23', :format => 'atom'
    should_route :get, "/projects/23/issues.xml", :controller => 'issues', :action => 'index', :project_id => '23', :format => 'xml'
    should_route :get, "/issues/64", :controller => 'issues', :action => 'show', :id => '64'
    should_route :get, "/issues/64.pdf", :controller => 'issues', :action => 'show', :id => '64', :format => 'pdf'
    should_route :get, "/issues/64.atom", :controller => 'issues', :action => 'show', :id => '64', :format => 'atom'
    should_route :get, "/issues/64.xml", :controller => 'issues', :action => 'show', :id => '64', :format => 'xml'

    should_route :get, "/projects/23/issues/new", :controller => 'issues', :action => 'new', :project_id => '23'
      
    should_route :get, "/issues/64/edit", :controller => 'issues', :action => 'edit', :id => '64'
    # TODO: Should use PUT
    should_route :post, "/issues/64/edit", :controller => 'issues', :action => 'edit', :id => '64'

    # TODO: Should use DELETE
    should_route :post, "/issues/64/destroy", :controller => 'issues', :action => 'destroy', :id => '64'
    
    # Extra actions
    should_route :get, "/projects/23/issues/64/copy", :controller => 'issues', :action => 'new', :project_id => '23', :copy_from => '64'

    should_route :get, "/issues/1/move", :controller => 'issues', :action => 'move', :id => '1'
    should_route :post, "/issues/1/move", :controller => 'issues', :action => 'move', :id => '1'
    
    should_route :post, "/issues/1/quoted", :controller => 'issues', :action => 'reply', :id => '1'

    should_route :get, "/issues/calendar", :controller => 'issues', :action => 'calendar'
    should_route :post, "/issues/calendar", :controller => 'issues', :action => 'calendar'
    should_route :get, "/projects/project-name/issues/calendar", :controller => 'issues', :action => 'calendar', :project_id => 'project-name'
    should_route :post, "/projects/project-name/issues/calendar", :controller => 'issues', :action => 'calendar', :project_id => 'project-name'

    should_route :get, "/issues/gantt", :controller => 'issues', :action => 'gantt'
    should_route :post, "/issues/gantt", :controller => 'issues', :action => 'gantt'
    should_route :get, "/projects/project-name/issues/gantt", :controller => 'issues', :action => 'gantt', :project_id => 'project-name'
    should_route :post, "/projects/project-name/issues/gantt", :controller => 'issues', :action => 'gantt', :project_id => 'project-name'
  end
  
  context "issue reports" do
    should_route :get, "/projects/567/issues/report", :controller => 'reports', :action => 'issue_report', :id => '567'
    should_route :get, "/projects/567/issues/report/assigned_to", :controller => 'reports', :action => 'issue_report_details', :id => '567', :detail => 'assigned_to'
  end
end
