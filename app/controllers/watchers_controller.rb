# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

class WatchersController < ApplicationController
  layout 'base'
  before_filter :require_login, :find_project, :check_project_privacy
  
  def add
    @issue.add_watcher(logged_in_user)
    redirect_to :controller => 'issues', :action => 'show', :id => @issue
  end
  
  def remove
    @issue.remove_watcher(logged_in_user)
    redirect_to :controller => 'issues', :action => 'show', :id => @issue
  end

private

  def find_project
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  end
end
