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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackageSquashTMTabController < ApplicationController
  include OpTurbo::ComponentStream

  load_and_authorize_with_permission_in_project :view_squashtm
  authorize_with_permission :manage_squashtm_requirements, only: %i[requirement_options]

  before_action :set_work_package
  before_action :set_view_model

  def index
    tab_component = SquashTMIntegration::WorkPackageSquashTMTabComponent.new(@view_model)
    replace_via_turbo_stream(component: tab_component)

    respond_to_with_turbo_streams do |format|
      format.html do
        render(tab_component, layout: false)
      end
    end
  end

  def requirement
    return render_404 unless @view_model.status == :linked

    linked_requirement = requirement_loader.load_linked_requirement(@view_model.work_package_link.stored_squashtm_requirement_id)
    render(SquashTMIntegration::WorkPackageTab::LinkedRequirementComponent.new(@view_model, linked_requirement:),
           layout: false)
  end

  def requirement_options
    return render_404 unless @view_model.status == :not_linked

    requirement_options = requirement_loader.load_project_requirements(@view_model.project_link.squashtm_project_id)
    render(SquashTMIntegration::WorkPackageTab::RequirementLinkFormComponent.new(@view_model, requirement_options:),
           layout: false)
  end

  private

  def set_work_package
    @work_package = @project.work_packages.visible.find(params.expect(:work_package_id))
  end

  def set_view_model
    @view_model = SquashTMIntegration::WorkPackageSquashTMTabViewModel.new(work_package: @work_package, user: current_user)
  end

  def requirement_loader
    SquashTMIntegration::RequirementLoader.new(@view_model.client)
  end
end
