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

module Admin
  module Settings
    class RepositoriesSettingsForm < ApplicationForm
      class SysApiForm < ApplicationForm
        settings_form do |sf|
          sf.text_field(
            name: :sys_api_key,
            id: "settings_sys_api_key",
            disabled: !Setting.sys_api_enabled?,
            input_width: :medium,
            data: {
              disable_when_checked_target: "effect",
              target_name: "sys_api_key"
            }
          )
        end
      end

      delegate :simple_format, to: :@view_context

      settings_form do |sf|
        sf.check_box(
          name: :autofetch_changesets,
          caption: simple_format(I18n.t("repositories.autofetch_information"))
        )

        sf.text_field(
          name: :repository_storage_cache_minutes,
          type: :number,
          caption: simple_format(I18n.t("repositories.storage.update_timeout")),
          trailing_visual: {
            id: "settings_repository_storage_cache_minutes_unit", text: { text: I18n.t(:label_minute_plural) }
          },
          input_width: :small,
          aria: { describedby: "settings_repository_storage_cache_minutes_unit" }
        )

        sf.check_box(
          name: :sys_api_enabled,
          caption: I18n.t(:setting_sys_api_description),
          data: {
            target_name: "sys_api_key",
            disable_when_checked_target: "cause",
            show_when_checked_target: "cause"
          }
        ) do |sys_api_check_box|
          sys_api_check_box.nested_form(
            classes: ["mt-2", { "d-none" => !Setting.sys_api_enabled? }],
            data: {
              target_name: "sys_api_key",
              show_when_checked_target: "effect",
              show_when: "checked"
            }
          ) do |builder|
            SysApiForm.new(builder)
          end
        end

        # Primer, unlike Rails' check_box helper, does not render this auxilary hidden field for us.
        sf.hidden(
          name: "settings[enabled_scm][]",
          value: "",
          scope_name_to_model: false,
          scope_id_to_model: false
        )

        sf.check_box_group(
          name: :enabled_scm,
          values: available_scms
        )

        sf.select_list(
          name: :repositories_automatic_managed_vendor,
          caption: I18n.t("repositories.settings.automatic_managed_repos_text"),
          values: manageable_scms,
          input_width: :medium,
          include_blank: I18n.t("repositories.settings.automatic_managed_repos_disabled")
        )

        sf.text_field(
          name: :repositories_encodings,
          caption: I18n.t(:text_comma_separated),
          input_width: :medium
        )

        sf.text_field(
          name: :repository_log_display_limit,
          type: :number,
          input_width: :xsmall
        )

        sf.text_field(
          name: :repository_truncate_at,
          type: :number,
          input_width: :xsmall
        )
      end

      private

      def available_scms
        OpenProject::SCM::Manager.registered
          .map do |vendor, klass|
            [
              klass.vendor_name,
              vendor.to_s,
              {
                data: { disable_when_checked_target: "cause", target_name: vendor.to_s }
              }
            ]
          end
      end

      def manageable_scms
        OpenProject::SCM::Manager.manageable
          .map do |vendor, klass|
            [
              klass.vendor_name,
              vendor.to_s,
              {
                disabled: !klass.enabled?,
                data: { disable_when_checked_target: "effect", target_name: vendor.to_s }
              }
            ]
          end
      end
    end
  end
end
