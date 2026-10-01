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
  # Hosts the core progress modal inside a Primer dialog so a work package's
  # work / remaining work / % complete can be edited from the list. The modal
  # body keeps the `work_package_progress_modal` turbo frame the live preview
  # navigates, and carries its own submit button.
  class EditTotalWorkDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    DIALOG_ID = "edit-total-work-dialog"

    def initialize(modal_component:)
      super

      @modal_component = modal_component
    end

    private

    attr_reader :modal_component

    def title
      I18n.t("resource_management.work_package_list.context_menu.edit_total_work")
    end
  end
end
