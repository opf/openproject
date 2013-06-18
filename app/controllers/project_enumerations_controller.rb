#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class ProjectEnumerationsController < ApplicationController
  before_filter :find_project_by_project_id
  before_filter :authorize

  def update
    if request.put? && params[:enumerations]
      Project.transaction do
        params[:enumerations].each do |id, activity|
          @project.update_or_create_time_entry_activity(id, activity)
        end
      end
      flash[:notice] = l(:notice_successful_update)
    end

    redirect_to :controller => '/projects', :action => 'settings', :tab => 'activities', :id => @project
  end

  def destroy
    TimeEntryActivity.bulk_destroy(@project.time_entry_activities)

    flash[:notice] = l(:notice_successful_update)
    redirect_to :controller => '/projects', :action => 'settings', :tab => 'activities', :id => @project
  end

end
