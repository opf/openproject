# frozen_string_literal: true

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

module ::Calendar
  class CalendarsController < ApplicationController
    before_action :load_and_authorize_in_optional_project
    before_action :build_calendar_view, only: %i[new]
    before_action :authorize, except: %i[index new create]
    before_action :authorize_global, only: %i[index create]
    before_action :authorize_new, only: %i[new]
    authorization_checked! :new
    authorize_with_permission :add_work_packages, only: %i[split_create]

    before_action :find_calendar, only: %i[show split_view destroy]
    menu_item :calendar_view

    include Layout
    include PaginationHelper
    include SortHelper
    include WorkPackages::WithSplitView

    def index
      @views = visible_views
      render "index", locals: { menu_name: project_or_global_menu }
    end

    def show
      render
    end

    def split_view
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_view", layout: false
          else
            render :show
          end
        end
      end
    end

    def split_create
      respond_to do |format|
        format.html do
          if turbo_frame_request?
            render "work_packages/split_create", layout: false
          else
            render :show
          end
        end
      end
    end

    def new
      # In a project context, show the calendar view with an unsaved query.
      # In the global context (no project), show the form so the user can select a project.
      render :show if @project
    end

    def create
      service_result = create_service_class.new(user: User.current)
                                           .call(calendar_view_params)

      @view = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_calendar_path(@project || @view.query.project, @view.query)
      else
        render action: :new, status: :unprocessable_entity
      end
    end

    def destroy
      if @view.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index, status: :see_other
    end

    private

    # In project context, `new` renders the calendar view and needs the same project-level
    # permission as `show`. In global context (no project), it shows the creation form.
    def authorize_new
      @project ? authorize : authorize_global
    end

    def split_view_base_route
      # Unsaved calendars use the /new path (no :id).
      # In that case @view is nil and we return the /new path as the base route
      # so that the split view close button navigates back correctly.
      if @view
        project_calendar_path(@project, @view, request.query_parameters)
      else
        new_project_calendar_path(@project, request.query_parameters)
      end
    end

    def build_calendar_view
      @view = Query.new
    end

    def create_service_class
      Calendar::Views::GlobalCreateService
    end

    def calendar_view_params
      params.expect(query: %i[name public starred project_id])
    end

    def visible_views
      base_query = Query
                     .visible(current_user)
                     .joins(:views, :project)
                     .where("views.type" => "work_packages_calendar")

      if @project
        base_query = base_query.where("queries.project_id" => @project.id)
      end

      base_query.order("queries.name ASC")
    end

    def find_calendar
      # split_view is also reachable via the /new collection path
      # (e.g. /calendars/new/details/:wp_id) which carries no :id.
      # In that case @view remains nil and split_view_base_route handles it.
      return if params[:id].blank?

      query_scope = Query.visible(current_user)
      query_scope = query_scope.where(project_id: @project.id) if @project

      @view = query_scope.find(params[:id])
    end
  end
end
