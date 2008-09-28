# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class WorkflowsController < ApplicationController
  before_filter :require_admin

  def index
    @workflow_counts = Workflow.count_by_tracker_and_role
  end
  
  def edit
    @role = Role.find_by_id(params[:role_id])
    @tracker = Tracker.find_by_id(params[:tracker_id])    
    
    if request.post?
      Workflow.destroy_all( ["role_id=? and tracker_id=?", @role.id, @tracker.id])
      (params[:issue_status] || []).each { |old, news| 
        news.each { |new| 
          @role.workflows.build(:tracker_id => @tracker.id, :old_status_id => old, :new_status_id => new) 
        }
      }
      if @role.save
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'edit', :role_id => @role, :tracker_id => @tracker
      end
    end
    @roles = Role.find(:all, :order => 'builtin, position')
    @trackers = Tracker.find(:all, :order => 'position')
    @statuses = IssueStatus.find(:all, :order => 'position')
  end
end
