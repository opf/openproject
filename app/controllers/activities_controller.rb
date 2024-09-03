#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class ActivitiesController < ApplicationController
  include Layout

  menu_item :activity
  before_action :warn_if_no_projects_visible,
                :load_and_authorize_in_optional_project,
                :verify_activities_module_activated,
                :determine_subprojects,
                :determine_author,
                :set_activity

  before_action :determine_date_range,
                :set_current_activity_page,
                only: :index

  after_action :set_session

  accept_key_auth :index

  def index
    @events = @activity.events(from: @date_from.to_datetime, to: @date_to.to_datetime)

    respond_to do |format|
      format.html do
        respond_html
      end
      format.atom do
        respond_atom
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    op_handle_warning "Failed to find all resources in activities: #{e.message}"
    render_404 I18n.t(:error_can_not_find_all_resources)
  end

  def menu
    render layout: nil
  end

  private

  def set_activity
    @activity = Activities::Fetcher.new(User.current,
                                        project: @project,
                                        with_subprojects: @with_subprojects,
                                        author: @author,
                                        scope: activity_scope)
  end

  def verify_activities_module_activated
    render_403 if @project && !@project.module_enabled?("activity")
  end

  def determine_date_range
    @days = Setting.activity_days_default.to_i

    if params[:from]
      begin; @date_to = params[:from].to_date + 1.day; rescue StandardError; end
    end

    @date_to ||= User.current.today + 1.day
    @date_from = @date_to - @days
  end

  def determine_subprojects
    # In OP < 13.0 session[:activity] was an Array.
    # If such a session is still present, we need to reset it.
    # This line can probably be removed in OP 14.0.
    session[:activity] = nil unless session[:activity].is_a?(Hash)

    @with_subprojects = if params[:with_subprojects].nil? &&
                          (session[:activity].nil? || session[:activity][:with_subprojects].nil?)
                          Setting.display_subprojects_work_packages?
                        elsif params[:with_subprojects].nil?
                          session[:activity][:with_subprojects]
                        else
                          params[:with_subprojects] == "1"
                        end
  end

  def determine_author
    @author = params[:user_id].blank? ? nil : User.active.find(params[:user_id])
  end

  def respond_html
    render locals: { menu_name: project_or_global_menu }
  end

  def respond_atom
    title = t(:label_activity)
    if @author
      title = @author.name
    elsif @activity.scope.size == 1
      title = t("label_#{@activity.scope.first.singularize}_plural")
    end
    render_feed(@events, title: "#{@project || Setting.app_title}: #{title}")
  end

  def activity_scope
    if params[:event_types]
      params[:event_types]
    elsif session[:activity]
      session[:activity][:scope]
    elsif @author.nil?
      :default
    else
      :all
    end
  end

  def set_current_activity_page
    @activity_page = @project ? "projects/#{@project.identifier}" : "all"
  end

  def set_session
    session[:activity] = { scope: @activity.scope,
                           with_subprojects: @with_subprojects }
  end

  def warn_if_no_projects_visible
    unless current_user.allowed_in_any_project?(:view_project_activity)
      render_404(message: I18n.t("homescreen.additional.no_visible_projects"))
    end
  end
end
