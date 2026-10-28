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

module SquashTMIntegration
  class WorkPackageRequirementLinksController < ApplicationController
    include OpTurbo::ComponentStream
    include OpTurbo::FlashStreamHelper

    load_and_authorize_with_permission_in_project :manage_squashtm_links

    before_action :set_work_package
    before_action :set_work_package_link
    before_action :require_persisted_work_package_link, only: %i[destroy_dialog destroy]

    def update
      result = save_work_package_link

      if result.success?
        redirect_to_tab
      else
        tab_state = WorkPackageTabState.new(work_package: @work_package, user: current_user, work_package_link: result.result)
        replace_via_turbo_stream(component: WorkPackageSquashTMTabComponent.new(tab_state), status: :unprocessable_entity)
        respond_with_turbo_streams
      end
    end

    def destroy_dialog
      respond_with_dialog WorkPackageTab::DeleteRequirementLinkDialogComponent.new(@work_package_link)
    end

    def destroy
      result = WorkPackageLinks::DeleteService.new(user: current_user, model: @work_package_link).call

      if result.success?
        redirect_to_tab
      else
        render_error_flash_message_via_turbo_stream(message: result.errors.full_messages.to_sentence)
        respond_with_turbo_streams
      end
    end

    private

    def set_work_package
      @work_package = @project.work_packages.visible.find(params.expect(:work_package_id))
    end

    def set_work_package_link
      @work_package_link = WorkPackageLink.find_or_initialize_by(work_package: @work_package)
    end

    def require_persisted_work_package_link
      render_404 unless @work_package_link.persisted?
    end

    def save_work_package_link
      attributes = params.expect(squashtm_work_package_link: %i[squashtm_requirement_id]).to_h.symbolize_keys

      if @work_package_link.persisted?
        WorkPackageLinks::UpdateService.new(user: current_user, model: @work_package_link).call(attributes)
      else
        WorkPackageLinks::CreateService.new(user: current_user).call(attributes.merge(work_package: @work_package))
      end
    end

    def redirect_to_tab
      redirect_to project_work_package_squashtm_tab_index_path(@project, @work_package), status: :see_other
    end
  end
end
