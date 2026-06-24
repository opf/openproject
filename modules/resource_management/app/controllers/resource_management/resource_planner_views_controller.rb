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
  # TODO - separate controllers per view?

  class ResourcePlannerViewsController < BaseController
    include OpTurbo::ComponentStream
    include PlannerViewContent

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_resource_planner
    before_action :find_view,
                  only: %i[show edit update destroy
                           new_work_package add_work_package remove_work_package
                           move_work_package reorder_work_package
                           new_user add_user remove_user]
    # The controller-level :authorize only grants read access; mutating a view's
    # contents additionally requires ownership or manage-public.
    before_action :authorize_manage_contents,
                  only: %i[new_work_package add_work_package remove_work_package
                           move_work_package reorder_work_package
                           new_user add_user remove_user]

    def show
      @content_component = work_package_list_content(@view)
    end

    def new
      if params[:view_class_name].present?
        render_configure_step(build_view)
      else
        respond_with_dialog ResourcePlannerViews::NewDialogComponent.new(
          resource_planner: @resource_planner,
          project: @project
        )
      end
    end

    def edit
      respond_with_dialog ResourcePlannerViews::EditDialogComponent.new(
        view: @view,
        project: @project,
        resource_planner: @resource_planner
      )
    end

    def create
      view_class = allowed_view_class(params[:view_class_name])
      return render_400(message: "Invalid view type") if view_class.nil?

      call = ResourcePlannerViews::CreateService
               .new(user: current_user, model: build_view(view_class:))
               .call(create_params)

      call.success? ? render_create_success(call.result) : render_configure_step(call.result, status: :unprocessable_entity)
    end

    def update
      call = ResourcePlannerViews::UpdateService
               .new(user: current_user, model: @view)
               .call(view_params)

      call.success? ? render_update_success(call.result) : render_edit_step(call.result, status: :unprocessable_entity)
    end

    def destroy
      call = ResourcePlannerViews::DeleteService.new(user: current_user, model: @view).call

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_delete)
      else
        flash[:error] = call.message
      end

      redirect_to project_resource_planner_path(@project, @resource_planner), status: :see_other
    end

    def new_work_package
      respond_with_dialog ResourcePlannerViews::WorkPackageList::AddWorkPackageDialogComponent.new(
        view: @view,
        project: @project,
        resource_planner: @resource_planner
      )
    end

    def add_work_package
      work_package = WorkPackage
                       .visible(current_user)
                       .where(project: @project)
                       .find_by(id: params[:work_package_id])

      return render_400(message: I18n.t(:notice_file_not_found)) if work_package.nil?

      append_work_package(work_package)

      replace_view_content
      close_dialog_via_turbo_stream(
        "##{ResourcePlannerViews::WorkPackageList::AddWorkPackageDialogComponent::DIALOG_ID}"
      )
      respond_with_turbo_streams
    end

    def remove_work_package
      @view.effective_query
           .ordered_work_packages
           .where(work_package_id: params[:work_package_id])
           .destroy_all

      replace_view_content
      respond_with_turbo_streams
    end

    def move_work_package
      move_to_index(params[:work_package_id]) do |index, count|
        case params[:direction].to_s
        when "top" then 0
        when "bottom" then count - 1
        when "up" then index - 1
        when "down" then index + 1
        end
      end

      replace_view_content
      respond_with_turbo_streams
    end

    # The drag-and-drop controller posts a 1-based drop index; convert to 0-based.
    def reorder_work_package
      move_to_index(params[:work_package_id]) { params[:position].to_i - 1 }

      replace_view_content
      respond_with_turbo_streams
    end

    def new_user
      respond_with_dialog ResourcePlannerViews::UserCardList::AddUserDialogComponent.new(
        view: @view,
        project: @project,
        resource_planner: @resource_planner
      )
    end

    def add_user
      user = User.user.visible(current_user).in_project(@project).find_by(id: params[:user_id])

      return render_400(message: I18n.t(:notice_file_not_found)) if user.nil?

      append_user(user)

      replace_view_content
      close_dialog_via_turbo_stream(
        "##{ResourcePlannerViews::UserCardList::AddUserDialogComponent::DIALOG_ID}"
      )
      respond_with_turbo_streams
    end

    def remove_user
      @view.effective_query
           .ordered_entities
           .where(entity_type: "Principal", entity_id: params[:user_id])
           .destroy_all

      replace_view_content
      respond_with_turbo_streams
    end

    private

    def append_user(user)
      query = @view.effective_query
      return if query.ordered_entities.exists?(entity_type: "Principal", entity_id: user.id)

      next_position = (query.ordered_entities.maximum(:position) || 0) + 1
      query.ordered_entities.create!(entity: user, position: next_position)
    end

    def replace_view_content
      replace_via_turbo_stream(component: work_package_list_content(@view))
    end

    def append_work_package(work_package)
      query = @view.effective_query
      return if query.ordered_work_packages.exists?(work_package_id: work_package.id)

      next_position = (query.ordered_work_packages.maximum(:position) || 0) + 1
      query.ordered_work_packages.create!(work_package:, position: next_position)
    end

    # Positions are re-packed 1..n afterwards so menu moves and drag-drop stay
    # consistent and sparse positions left by the work-package table are tolerated.
    def move_to_index(work_package_id)
      ordered = @view.effective_query.ordered_work_packages.order(:position).to_a
      from = ordered.index { |owp| owp.work_package_id == work_package_id.to_i }
      return if from.nil?

      target = yield(from, ordered.size).clamp(0, ordered.size - 1)
      reorder_and_repack(ordered, from, target) unless target == from
    end

    def reorder_and_repack(ordered, from, target)
      ordered.insert(target, ordered.delete_at(from))
      repack_positions(ordered)
    end

    def repack_positions(ordered)
      ordered.each_with_index do |owp, index|
        owp.update_column(:position, index + 1) unless owp.position == index + 1
      end
    end

    def render_configure_step(view, status: :ok)
      update_dialog_title_via_turbo_stream(
        ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
        new_title: I18n.t("resource_management.configure_view_dialog.title")
      )
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FormComponent.new(
          view:,
          url: project_resource_planner_views_path(@project, @resource_planner),
          hidden_fields: { view_class_name: view.class.name },
          dialog_id: ResourcePlannerViews::NewDialogComponent::DIALOG_ID,
          filter_query: view.build_default_query
        ),
        status:
      )
      replace_via_turbo_stream(component: ResourcePlannerViews::ConfigureStep::FooterComponent.new)
      respond_with_turbo_streams
    end

    # The edit dialog's footer is static, so only the form is replaced.
    def render_edit_step(view, status: :ok)
      replace_via_turbo_stream(
        component: ResourcePlannerViews::ConfigureStep::FormComponent.new(
          view:,
          url: project_resource_planner_view_path(@project, @resource_planner, view),
          method: :patch,
          form_id: ResourcePlannerViews::EditDialogComponent::FORM_ID,
          dialog_id: ResourcePlannerViews::EditDialogComponent::DIALOG_ID,
          filter_query: view.effective_query
        ),
        status:
      )
      respond_with_turbo_streams
    end

    def render_update_success(view)
      # The cached children association still holds the pre-update name.
      @resource_planner.children.reload

      replace_via_turbo_stream(
        component: ResourcePlanners::SubViewsComponent.new(
          resource_planner: @resource_planner,
          selected_view: view
        )
      )
      replace_via_turbo_stream(component: work_package_list_content(view))
      close_dialog_via_turbo_stream("##{ResourcePlannerViews::EditDialogComponent::DIALOG_ID}")
      respond_with_turbo_streams
    end

    def build_view(view_class: allowed_view_class(params[:view_class_name]))
      view_class.new(parent: @resource_planner, project: @project, principal: current_user,
                     name: default_view_name(view_class))
    end

    # Pre-fill the name with the view type's label so the configure step is not
    # a second blank "Name" field after naming the planner. A submitted name
    # overrides it.
    def default_view_name(view_class)
      I18n.t("resource_management.view_types.#{view_class.model_name.i18n_key}.label",
             default: view_class.model_name.human)
    end

    def view_params
      params.expect(view: %i[name]).to_h.merge(query_configuration_params)
    end

    # The radio is scoped to the `:view` form (`view[filter_mode]`) while the
    # filters JSON is top-level, so read the toggle from either place.
    def query_configuration_params
      { filters: params[:filters], filter_mode: filter_mode_param }
    end

    def filter_mode_param
      params.dig(:view, :filter_mode) || params[:filter_mode]
    end

    def create_params
      view_params.merge(parent: @resource_planner, project: @project, principal: current_user)
    end

    def render_create_success(view)
      render turbo_stream: turbo_stream.redirect_to(
        project_resource_planner_view_path(@project, @resource_planner, view)
      )
    end

    def allowed_view_class(name)
      ResourcePlanner.allowed_child_class(name)
    end

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(:resource_planner_id))
    end

    def find_view
      @view = @resource_planner.children.find(params.expect(:id))
    end

    def authorize_manage_contents
      deny_access unless ResourcePlannerViews::ManageContentsContract.new(@view, current_user).valid?
    end
  end
end
