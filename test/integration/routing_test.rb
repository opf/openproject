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

require "#{File.dirname(__FILE__)}/../test_helper"

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

    should_route :get, "/issues/auto_complete", :controller => 'issues', :action => 'auto_complete'
  end
  
  context "issue reports" do
    should_route :get, "/projects/567/issues/report", :controller => 'reports', :action => 'issue_report', :id => '567'
    should_route :get, "/projects/567/issues/report/assigned_to", :controller => 'reports', :action => 'issue_report_details', :id => '567', :detail => 'assigned_to'
  end

  context "users" do
    should_route :get, "/users", :controller => 'users', :action => 'index'
    should_route :get, "/users/44", :controller => 'users', :action => 'show', :id => '44'
    should_route :get, "/users/new", :controller => 'users', :action => 'add'
    should_route :get, "/users/444/edit", :controller => 'users', :action => 'edit', :id => '444'
    should_route :get, "/users/222/edit/membership", :controller => 'users', :action => 'edit', :id => '222', :tab => 'membership'

    should_route :post, "/users/new", :controller => 'users', :action => 'add'
    should_route :post, "/users/444/edit", :controller => 'users', :action => 'edit', :id => '444'
    should_route :post, "/users/123/memberships", :controller => 'users', :action => 'edit_membership', :id => '123'
    should_route :post, "/users/123/memberships/55", :controller => 'users', :action => 'edit_membership', :id => '123', :membership_id => '55'
    should_route :post, "/users/567/memberships/12/destroy", :controller => 'users', :action => 'destroy_membership', :id => '567', :membership_id => '12'
  end

  context "versions" do
    should_route :get, "/projects/foo/versions/new", :controller => 'versions', :action => 'new', :project_id => 'foo'

    should_route :post, "/projects/foo/versions/new", :controller => 'versions', :action => 'new', :project_id => 'foo'
  end

  context "wikis" do
    should_route :get, "/projects/567/wiki", :controller => 'wiki', :action => 'index', :id => '567'
    should_route :get, "/projects/567/wiki/lalala", :controller => 'wiki', :action => 'index', :id => '567', :page => 'lalala'
    should_route :get, "/projects/567/wiki/my_page/edit", :controller => 'wiki', :action => 'edit', :id => '567', :page => 'my_page'
    should_route :get, "/projects/1/wiki/CookBook_documentation/history", :controller => 'wiki', :action => 'history', :id => '1', :page => 'CookBook_documentation'
    should_route :get, "/projects/1/wiki/CookBook_documentation/diff/2/vs/1", :controller => 'wiki', :action => 'diff', :id => '1', :page => 'CookBook_documentation', :version => '2', :version_from => '1'
    should_route :get, "/projects/1/wiki/CookBook_documentation/annotate/2", :controller => 'wiki', :action => 'annotate', :id => '1', :page => 'CookBook_documentation', :version => '2'
    should_route :get, "/projects/22/wiki/ladida/rename", :controller => 'wiki', :action => 'rename', :id => '22', :page => 'ladida'
    should_route :get, "/projects/567/wiki/page_index", :controller => 'wiki', :action => 'special', :id => '567', :page => 'page_index'
    should_route :get, "/projects/567/wiki/Page_Index", :controller => 'wiki', :action => 'special', :id => '567', :page => 'Page_Index'
    should_route :get, "/projects/567/wiki/date_index", :controller => 'wiki', :action => 'special', :id => '567', :page => 'date_index'
    should_route :get, "/projects/567/wiki/export", :controller => 'wiki', :action => 'special', :id => '567', :page => 'export'
    
    should_route :post, "/projects/567/wiki/my_page/edit", :controller => 'wiki', :action => 'edit', :id => '567', :page => 'my_page'
    should_route :post, "/projects/567/wiki/CookBook_documentation/preview", :controller => 'wiki', :action => 'preview', :id => '567', :page => 'CookBook_documentation'
    should_route :post, "/projects/22/wiki/ladida/rename", :controller => 'wiki', :action => 'rename', :id => '22', :page => 'ladida'
    should_route :post, "/projects/22/wiki/ladida/destroy", :controller => 'wiki', :action => 'destroy', :id => '22', :page => 'ladida'
    should_route :post, "/projects/22/wiki/ladida/protect", :controller => 'wiki', :action => 'protect', :id => '22', :page => 'ladida'
  end

  context "administration panel" do
    should_route :get, "/admin/projects", :controller => 'admin', :action => 'projects'
  end
end
