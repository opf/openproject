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
  class WorkPackagesIdentifierController < ::Admin::SettingsController
    include OpTurbo::ComponentStream

    current_menu_item :show do
      :work_packages_identifier
    end

    def show
      @form_state = ProjectIdentifiers::IdentifierAutofix.job_in_progress? ? :change_in_progress : :edit
    end

    def update
      case params.dig(:settings, :work_packages_identifier)
      when Setting::WorkPackageIdentifier::SEMANTIC  then switch_to_semantic
      when Setting::WorkPackageIdentifier::CLASSIC   then switch_to_classic
      else                                                render_400
      end
    end

    def confirm_dialog
      respond_with_dialog WorkPackages::Admin::Settings::ChangeIdentifiersDialogComponent.new
    end

    def status
      state = ProjectIdentifiers::IdentifierAutofix.job_in_progress? ? :change_in_progress : :completed
      replace_via_turbo_stream(
        component: WorkPackages::Admin::Settings::IdentifierSettingsFormComponent.new(state:)
      )
      respond_with_turbo_streams
    end

    private

    def switch_to_semantic
      unless ProjectIdentifiers::IdentifierAutofix.job_in_progress?
        ProjectIdentifiers::ConvertInstanceToSemanticIdsJob.perform_later
      end
      redirect_to action: "show"
    end

    def switch_to_classic
      call = update_service.new(user: current_user)
                                    .call(work_packages_identifier: Setting::WorkPackageIdentifier::CLASSIC)
      call.on_success do
        unless ProjectIdentifiers::IdentifierAutofix.job_in_progress?
          ProjectIdentifiers::RevertInstanceToClassicIdsJob.perform_later
        end
        redirect_to action: "show"
      end
      call.on_failure { failure_callback(call) }
    end

  end
end
