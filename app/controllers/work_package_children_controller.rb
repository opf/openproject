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

class WorkPackageChildrenController < ApplicationController
  include OpTurbo::ComponentStream
  include WorkPackages::Dialogs::Creation
  include WorkPackageRelationsTab::UpdateResponses

  before_action :set_work_package
  before_action :authorize

  authorize_with_permission :add_work_packages

  def new
    respond_with_dialog(dialog_component)
  end

  def create
    service_result = WorkPackages::CreateService
      .new(user: current_user)
      .call(child_params)

    if service_result.failure?
      update_via_turbo_stream(component: form_component(service_result.result), status: :bad_request)
    end

    respond_with_relations_tab_update(
      service_result,
      message: I18n.t("work_package_relations_tab.relations.label_new_child_created"),
      relation_to_scroll_to: service_result.result
    )
  end

  def refresh_form
    update_via_turbo_stream(component: form_component(refreshed_work_package))

    respond_with_turbo_streams
  end

  private

  def dialog_component
    WorkPackages::Dialogs::CreateDialogComponent.new(
      work_package: build_work_package,
      project: @project,
      keep_open_on_success: false,
      **form_urls
    )
  end

  def form_component(work_package)
    WorkPackages::Dialogs::CreateFormComponent.new(work_package:, project: @project, **form_urls)
  end

  def form_urls
    {
      submit_url: work_package_children_path(@work_package),
      refresh_url: refresh_form_work_package_children_path(@work_package)
    }
  end

  def child_params
    create_params.merge(parent: @work_package)
  end

  def set_work_package
    @work_package = WorkPackage.visible.find(params.expect(:work_package_id))
    @project = @work_package.project
  end
end
