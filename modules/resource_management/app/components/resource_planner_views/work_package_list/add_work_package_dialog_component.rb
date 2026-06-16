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

module ResourcePlannerViews::WorkPackageList
  class AddWorkPackageDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    DIALOG_ID = "rm-add-work-package-dialog"
    FORM_ID = "rm-add-work-package-form"

    def initialize(view:, project:, resource_planner:)
      super

      @view = view
      @project = project
      @resource_planner = resource_planner
    end

    private

    def title
      I18n.t("resource_management.work_package_list.add_work_package_dialog.title")
    end

    def form_url
      work_packages_project_resource_planner_view_path(@project, @resource_planner, @view)
    end

    def already_added_work_package_ids
      @view.effective_query&.ordered_work_packages&.pluck(:work_package_id) || []
    end
  end
end
