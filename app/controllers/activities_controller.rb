#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class ActivitiesController < ApplicationController
  menu_item :activity
  before_filter :find_optional_project, :verify_activities_module_activated
  accept_key_auth :index

  def index
    @days = Setting.activity_days_default.to_i

    if params[:from]
      begin; @date_to = params[:from].to_date + 1; rescue; end
    end

    @date_to ||= Date.today + 1
    @date_from = @date_to - @days
    @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_work_packages? : (params[:with_subprojects] == '1')
    @author = (params[:user_id].blank? ? nil : User.active.find(params[:user_id]))

    @activity = Redmine::Activity::Fetcher.new(User.current, project: @project,
                                                             with_subprojects: @with_subprojects,
                                                             author: @author)

    set_activity_scope

    events = @activity.events(@date_from, @date_to)
    censor_events_from_projects_with_disabled_activity!(events) unless @project

    if events.empty? || stale?(etag: [@activity.scope, @date_to, @date_from, @with_subprojects, @author, events.first, User.current, current_language])
      respond_to do |format|
        format.html {
          @events_by_day = events.group_by { |e| e.event_datetime.to_date }
          render layout: false if request.xhr?
        }
        format.atom {
          title = l(:label_activity)
          if @author
            title = @author.name
          elsif @activity.scope.size == 1
            title = l("label_#{@activity.scope.first.singularize}_plural")
          end
          render_feed(events, title: "#{@project || Setting.app_title}: #{title}")
        }
      end
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  # TODO: this should now be functionally identical to the implementation in application_controller
  # double check and remove
  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def verify_activities_module_activated
    render_403 if @project && !@project.module_enabled?('activity')
  end

  # Do not show events, which are associated with projects where activities are disabled.
  # In a better world this would be implemented (with better performance) in SQL.
  # TODO: make the world a better place.
  def censor_events_from_projects_with_disabled_activity!(events)
    allowed_project_ids = EnabledModule.where(name: 'activity').map(&:project_id)
    events.select! do |event|
      event.project_id.nil? || allowed_project_ids.include?(event.project_id)
    end
  end

  def set_activity_scope
    if params[:apply]
      @activity.scope_select { |t| !params["show_#{t}"].nil? }
    elsif session[:activity]
      @activity.scope = session[:activity]
    else
      @activity.scope = (@author.nil? ? :default : :all)
    end

    session[:activity] = @activity.scope
  end
end
