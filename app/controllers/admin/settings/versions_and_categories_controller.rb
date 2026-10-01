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

module Admin::Settings
  class VersionsAndCategoriesController < ::Admin::SettingsController
    include OpTurbo::ComponentStream

    current_menu_item :show do
      :versions_and_categories
    end

    def show
      @target_versions_state = target_versions_state
    end

    def enable_multiple_versions
      unless Setting.work_package_multiple_versions?
        result = Settings::UpdateService.new(user: current_user).call(work_package_multiple_versions: "1")
        Rails.logger.error(result.message) unless result.success?
      end

      replace_target_versions_section_via_turbo_stream(target_versions_state)
      respond_with_turbo_streams
    end

    def confirm_dialog
      respond_with_dialog WorkPackages::Admin::Settings::EnableMultipleVersionsDialogComponent.new
    end

    private

    def replace_target_versions_section_via_turbo_stream(state)
      replace_via_turbo_stream(
        component: WorkPackages::Admin::Settings::TargetVersionsSectionComponent.new(state:)
      )
    end

    def target_versions_state
      Setting.work_package_multiple_versions? ? :completed : :action_required
    end
  end
end
