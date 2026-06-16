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

module ResourceAllocations
  # The dialog shell around a work package's allocation list, with a footer to
  # allocate another resource.
  class ListDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    DIALOG_ID = "work-package-allocations-dialog"

    def initialize(project:, work_package:, allocations:, visible_principal_ids:, overbooked_ids: Set.new)
      super

      @project = project
      @work_package = work_package
      @allocations = allocations
      @visible_principal_ids = visible_principal_ids
      @overbooked_ids = overbooked_ids
    end

    private

    attr_reader :project, :work_package, :allocations, :visible_principal_ids, :overbooked_ids

    def title
      I18n.t("resource_management.work_package_allocations_dialog.title")
    end

    def allocate_resource_path
      new_project_resource_allocation_path(project, work_package_id: work_package.id)
    end
  end
end
