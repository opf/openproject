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
  # Edits a work package's progress (work / remaining work / % complete) from a
  # resource planner work package list, reusing the core progress modal. The
  # modal form posts back here so a successful save can close the dialog and
  # refresh the list inline, instead of going through the Angular-driven core
  # `WorkPackages::ProgressController` flow.
  class WorkPackageProgressController < BaseController
    include OpTurbo::ComponentStream
    include FlashMessagesHelper
    include PlannerViewContent
    include WorkPackages::Progress::ModalParams

    menu_item :resource_management

    layout false

    before_action :find_project_by_project_id
    before_action :find_resource_planner
    before_action :find_view
    before_action :find_work_package
    before_action :authorize_edit_work_package

    # The `.visible` finders above enforce read access (view_resource_planners /
    # view_work_packages); `authorize_edit_work_package` gates the edit itself.
    authorization_checked! :edit, :update, :preview

    def edit
      respond_with_dialog ResourcePlannerViews::WorkPackageList::EditTotalWorkDialogComponent.new(
        modal_component: progress_modal_component(submit_path: update_path)
      )
    end

    def preview
      set_progress_attributes_to_work_package

      render template: "work_packages/progress/modal",
             locals: { progress_modal_component: progress_modal_component(submit_path: update_path) }
    end

    def update
      call = WorkPackages::UpdateService
               .new(user: current_user, model: @work_package)
               .call(work_package_progress_params)

      call.success? ? render_update_success : render_update_failure(call)
    end

    private

    def render_update_success
      render_success_flash_message_via_turbo_stream(message: I18n.t(:notice_successful_update))
      close_dialog_via_turbo_stream(
        "##{ResourcePlannerViews::WorkPackageList::EditTotalWorkDialogComponent::DIALOG_ID}"
      )
      replace_via_turbo_stream(component: work_package_list_content(@view))
      respond_with_turbo_streams
    end

    def render_update_failure(call)
      extra_errors = extra_error_messages(call)
      render_error_flash_message_via_turbo_stream(message: extra_errors) if extra_errors.present?

      # `@work_package` already carries the rejected attributes and errors from
      # the failed service call, so the modal re-renders with them in place.
      update_via_turbo_stream(
        component: progress_modal_component(submit_path: update_path),
        method: "morph"
      )
      respond_with_turbo_streams(status: :unprocessable_entity)
    end

    def update_path
      project_resource_planner_view_work_package_progress_path(
        @project, @resource_planner, @view, @work_package
      )
    end

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .with_children
                            .find(params.expect(:resource_planner_id))
    end

    def find_view
      @view = @resource_planner.children.find(params.expect(:view_id))
    end

    def find_work_package
      @work_package = WorkPackage
                        .visible(current_user)
                        .where(project: @project)
                        .find(params.expect(:work_package_id))
    end

    def authorize_edit_work_package
      deny_access unless User.current.allowed_in_project?(:edit_work_packages, @project)
    end
  end
end
