# frozen_string_literal: true

# -- copyright
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
# ++

class WorkPackages::DialogsController < ApplicationController
  include OpTurbo::ComponentStream
  layout false

  before_action :find_project_by_project_id
  before_action :build_work_package, only: %i[new]

  authorize_with_permission :add_work_packages

  def new
    respond_with_dialog WorkPackages::Dialogs::CreateDialogComponent.new(work_package: @work_package, project: @project)
  end

  def create
    call = WorkPackages::CreateService.new(user: current_user).call(create_params)

    if call.success?
      flash[:notice] = create_success_message(call.result)
      redirect_back fallback_location: project_work_package_path(@project, call.result), status: :see_other
    else
      form_component = WorkPackages::Dialogs::CreateFormComponent.new(work_package: call.result, project: @project)
      update_via_turbo_stream(component: form_component, status: :bad_request)

      respond_with_turbo_streams
    end
  end

  def refresh_form
    call = WorkPackages::SetAttributesService.new(
      user: current_user,
      model: WorkPackage.new,
      contract_class: EmptyContract
    ).call(create_params)

    form_component = WorkPackages::Dialogs::CreateFormComponent.new(work_package: call.result, project: @project)
    update_via_turbo_stream(component: form_component)

    respond_with_turbo_streams
  end

  private

  def build_work_package
    initial = WorkPackage.new(project: @project)

    call = WorkPackages::SetAttributesService
      .new(model: initial, user: current_user, contract_class: WorkPackages::CreateContract)
      .call(new_params.reverse_merge(default_params(initial)))

    # We ignore errors here, as we only want to build the work package
    @work_package = call.result
    @work_package.errors.clear
    @work_package.custom_values.each { |cv| cv.errors.clear }
  end

  def new_params
    params.permit(*PermittedParams.permitted_attributes[:new_work_package])
  end

  def create_params
    permitted_params.update_work_package.merge(project: @project)
  end

  def default_params(work_package)
    contract = WorkPackages::CreateContract.new(work_package, current_user)

    {
      type: contract.assignable_types.first,
      project: @project
    }
  end

  def create_success_message(work_package)
    if work_package.child?
      I18n.t("work_package_relations_tab.relations.label_new_child_created")
    else
      I18n.t(:notice_successful_create)
    end
  end
end
