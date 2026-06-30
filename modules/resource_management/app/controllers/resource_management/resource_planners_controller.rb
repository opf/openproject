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
module ::ResourceManagement
  class ResourcePlannersController < BaseController
    include OpTurbo::ComponentStream
    include PlannerViewContent

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_resource_planner, only: %i[show edit update destroy toggle_public]
    before_action :build_resource_planner, only: %i[new]

    def index
      @resource_planners = ResourcePlanner
                             .visible(current_user)
                             .where(project: @project)
                             .order(:name)
    end

    def show
      @view = default_view
      @content_component = work_package_list_content(@view)
      render "resource_management/resource_planner_views/show"
    end

    def overview; end

    def new
      respond_with_dialog ResourcePlanners::NewDialogComponent.new(
        resource_planner: @resource_planner,
        project: @project
      )
    end

    def edit
      @resource_planner.favorite = @resource_planner.favorited_by?(current_user)

      respond_with_dialog ResourcePlanners::EditDialogComponent.new(
        resource_planner: @resource_planner,
        project: @project
      )
    end

    def create
      call = ResourcePlanners::CreateService
               .new(user: current_user)
               .call(create_params)

      @resource_planner = call.result

      call.success? ? render_create_success : render_create_failure(call)
    end

    def update
      permitted = update_params
      # Keep the favorite checkbox state on re-render; the flag is virtual and
      # applied by UpdateService rather than persisted on the planner.
      @resource_planner.favorite = permitted[:favorite] if permitted.key?(:favorite)

      call = ResourcePlanners::UpdateService
               .new(user: current_user, model: @resource_planner)
               .call(permitted)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_back_or_to(
          project_resource_planner_path(@project, @resource_planner), status: :see_other
        )
      else
        @resource_planner = call.result
        render_update_failure(call)
      end
    end

    def destroy
      ResourcePlanners::DeleteService
        .new(user: current_user, model: @resource_planner)
        .call
        .on_success { flash[:notice] = I18n.t(:notice_successful_delete) }
        .on_failure { |call| flash[:error] = call.message }

      redirect_to project_resource_planners_path(@project), status: :see_other
    end

    def toggle_public
      call = ResourcePlanners::TogglePublicService
               .new(user: current_user, model: @resource_planner)
               .call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = call.message
      end

      redirect_back_or_to(
        project_resource_planner_path(@project, @resource_planner), status: :see_other
      )
    end

    private

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(:id))
    end

    def build_resource_planner
      @resource_planner = ResourcePlanner.new(project: @project, principal: current_user)
    end

    def default_view
      children = @resource_planner.children
      children.find { |c| c.id == @resource_planner.default_view_id } || children.first
    end

    def create_params
      permitted_planner_params(default_view: true).merge(project: @project)
    end

    def update_params
      permitted_planner_params(default_view: false)
    end

    def permitted_planner_params(default_view:)
      extra = %i[favorite]
      extra << :default_view_class_name if default_view
      extra << :public if can_manage_public?

      permitted = resource_planner_params(extra:).to_h
      %i[favorite public].each do |key|
        permitted[key] = ActiveModel::Type::Boolean.new.cast(permitted[key]) if permitted.key?(key)
      end
      permitted
    end

    def resource_planner_params(extra: [])
      params.expect(resource_planner: %i[name start_date end_date] + extra)
    end

    def can_manage_public?
      current_user.allowed_in_project?(:manage_public_resource_planners, @project)
    end

    def render_create_success
      view_class = chosen_default_view_class
      return render_create_success_redirect if view_class.nil?

      advance_dialog_to_configure_view(view_class)
    end

    def render_create_success_redirect
      flash[:notice] = I18n.t(:notice_successful_create)
      redirect_to project_resource_planner_path(@project, @resource_planner)
    end

    def advance_dialog_to_configure_view(view_class)
      view = view_class.new(parent: @resource_planner, project: @project, principal: current_user)
      dialog = ResourcePlanners::NewDialogComponent

      update_dialog_title_via_turbo_stream(
        dialog::DIALOG_ID,
        new_title: I18n.t("resource_management.configure_view_dialog.title")
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FormComponent.new(
          view:,
          url: project_resource_planner_views_path(@project, @resource_planner),
          hidden_fields: { view_class_name: view_class.name },
          form_id: dialog::FORM_ID,
          dialog_id: dialog::DIALOG_ID,
          wrapper_key: ResourcePlanners::FormComponent.wrapper_key,
          filter_query: view.build_default_query
        )
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FooterComponent.new(
          dialog_id: dialog::DIALOG_ID,
          form_id: dialog::FORM_ID,
          footer_id: dialog::FOOTER_ID,
          cancel_href: project_resource_planners_path(@project)
        )
      )
      respond_with_turbo_streams
    end

    def chosen_default_view_class
      ResourcePlanner.allowed_child_class(params.dig(:resource_planner, :default_view_class_name))
    end

    def render_create_failure(call)
      update_via_turbo_stream(
        component: ResourcePlanners::FormComponent.new(
          resource_planner: @resource_planner,
          project: @project,
          base_errors: call.errors[:base]
        ),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end

    def render_update_failure(call)
      dialog = ResourcePlanners::EditDialogComponent

      update_via_turbo_stream(
        component: ResourcePlanners::FormComponent.new(
          resource_planner: @resource_planner,
          project: @project,
          base_errors: call.errors[:base],
          form_id: dialog::FORM_ID,
          dialog_id: dialog::DIALOG_ID,
          url: project_resource_planner_path(@project, @resource_planner),
          method: :patch,
          include_default_view: false
        ),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams
    end
  end
end
