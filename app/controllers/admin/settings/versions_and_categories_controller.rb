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
      state = target_versions_state

      if state == :action_required && Setting.work_package_multiple_versions_writable?
        WorkPackages::EnableMultipleVersionsJob.perform_later
        state = :in_progress
      end

      replace_target_versions_section_via_turbo_stream(state)
      respond_with_turbo_streams
    end

    def status
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

    # The job is checked before the setting because the setting only flips once the job
    # finishes, so a run in progress would otherwise be reported as :action_required.
    def target_versions_state
      if WorkPackages::EnableMultipleVersionsJob.in_progress?
        :in_progress
      elsif Setting.work_package_multiple_versions?
        :completed
      else
        :action_required
      end
    end
  end
end
