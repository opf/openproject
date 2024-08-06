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
    before_action :authorize_global, only: %i[index new create]

    before_action :find_calendar, only: %i[destroy]
    menu_item :calendar_view

    include Layout
    include PaginationHelper
    include SortHelper

    def index
      @views = visible_views
      render "index", locals: { menu_name: project_or_global_menu }
    end

    def show
      render layout: "angular/angular"
    end

    def new; end

    def create
      service_result = create_service_class.new(user: User.current)
                                           .call(calendar_view_params)

      @view = service_result.result

      if service_result.success?
        flash[:notice] = I18n.t(:notice_successful_create)
        redirect_to project_calendar_path(@project, @view.query)
      else
        render action: :new
      end
    end

    def destroy
      if @view.destroy
        flash[:notice] = t(:notice_successful_delete)
      else
        flash[:error] = t(:error_can_not_delete_entry)
      end

      redirect_to action: :index
    end

    private

    def build_calendar_view
      @view = Query.new
    end

    def create_service_class
      Calendar::Views::GlobalCreateService
    end

    def calendar_view_params
      params.require(:query).permit(:name, :public, :starred).merge(project_id: @project&.id)
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
      @view = Query
                .visible(current_user)
                .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
end
