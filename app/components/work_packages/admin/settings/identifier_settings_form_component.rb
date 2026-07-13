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
#

module WorkPackages
  module Admin
    module Settings
      class IdentifierSettingsFormComponent < ApplicationComponent
        include OpPrimer::FormHelpers
        include OpTurbo::Streamable

        STATES = %i[edit change_in_progress completed].freeze

        attr_reader :projects_data, :total_count, :state

        def initialize(state: :edit)
          raise ArgumentError, "Unknown state: #{state}" unless STATES.include?(state)

          super()
          @state = state
          if state == :edit
            result         = ProjectIdentifiers::IdentifierAutofix::PreviewQuery.new.call
            @projects_data = result.projects_data
            @total_count   = result.total_count
          else
            @projects_data = []
            @total_count   = 0
          end
        end

        def has_problematic_projects?
          total_count > 0
        end

        private

        def form_id = "wp-identifier-settings-form"

        def in_progress_banner_message
          key = if ProjectIdentifiers::IdentifierAutofix.reversion_in_progress?
                  "admin.settings.work_packages_identifier.in_progress.reverting_banner_message"
                else
                  "admin.settings.work_packages_identifier.in_progress.converting_banner_message"
                end
          I18n.t(key)
        end

        def show_autofix_section?
          state == :edit && Setting::WorkPackageIdentifier.semantic? && has_problematic_projects?
        end

        def change_in_progress? = state == :change_in_progress
        def completed?          = state == :completed

        def total_projects_count
          @total_projects_count ||= Project.count
        end

        def processed_projects_count
          [total_projects_count - remaining_projects_count, 0].max
        end

        def progress_percentage
          return 100 if total_projects_count.zero?

          [(processed_projects_count.to_f / total_projects_count * 100), 100].min.round
        end

        def in_progress_header
          key = ProjectIdentifiers::IdentifierAutofix.reversion_in_progress? ? :header_classic : :header_semantic
          I18n.t("admin.settings.work_packages_identifier.in_progress.#{key}")
        end

        def remaining_projects_count
          @remaining_projects_count ||=
            if ProjectIdentifiers::IdentifierAutofix.reversion_in_progress?
              Project.with_non_classic_identifier.count
            else
              ProjectIdentifiers::PendingProjectsFinder.count
            end
        end

        def wrapper_data_attrs
          if change_in_progress?
            poll_for_changes_controller_attrs
          else
            work_package_identifier_controller_attrs
          end
        end

        def poll_for_changes_controller_attrs
          {
            data: {
              controller: "poll-for-changes",
              poll_for_changes_url_value: url_helpers.status_admin_settings_work_packages_identifier_path,
              poll_for_changes_interval_value: 3000
            }
          }
        end

        def work_package_identifier_controller_attrs
          {
            data: {
              controller: "admin--work-packages-identifier",
              admin__work_packages_identifier_has_problematic_projects_value: has_problematic_projects?,
              admin__work_packages_identifier_current_value_value: Setting[:work_packages_identifier]
            }
          }
        end

        def radio_button_options
          if change_in_progress?
            {
              values: identifier_values(checked: nil),
              button_options: { disabled: true }
            }
          elsif completed?
            { values: identifier_values(checked: Setting[:work_packages_identifier]) }
          else
            { button_options: { data: { action: "change->admin--work-packages-identifier#handleChange" } } }
          end
        end

        def identifier_values(checked:)
          Setting::WorkPackageIdentifier::ALLOWED_VALUES.map do |v|
            { name: v, value: v, checked: v == checked }
          end
        end
      end
    end
  end
end
