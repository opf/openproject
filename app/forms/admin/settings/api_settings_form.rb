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

module Admin
  module Settings
    class APISettingsForm < ApplicationForm
      delegate :static_link_to, to: :@view_context

      class CORSForm < ApplicationForm
        settings_form do |sf|
          sf.text_area(
            name: :apiv3_cors_origins,
            rows: 5,
            disabled: !Setting.apiv3_cors_enabled?,
            data: {
              disable_when_checked_target: "effect",
              target_name: "apiv3_cors_enabled"
            }
          )
        end
      end

      settings_form do |sf|
        sf.check_box(name: :api_tokens_enabled, caption: I18n.t(:setting_api_tokens_enabled_caption))

        sf.text_field(
          name: :apiv3_max_page_size,
          type: :number,
          input_width: :xsmall,
          min: 50
        )

        sf.check_box(name: :apiv3_write_readonly_attributes)

        sf.fieldset_group(title: I18n.t("setting_apiv3_docs"), mt: 4) do |fg|
          fg.check_box(
            name: :apiv3_docs_enabled,
            caption: I18n.t(:setting_apiv3_docs_enabled_instructions_warning)
          )
        end

        sf.fieldset_group(title: I18n.t("setting_apiv3_cors_title")) do |fg|
          fg.check_box(
            name: :apiv3_cors_enabled,
            data: {
              target_name: "apiv3_cors_enabled",
              disable_when_checked_target: "cause",
              show_when_checked_target: "cause"
            }
          ) do |apiv3_cors_check_box|
            apiv3_cors_check_box.nested_form(
              classes: ["mt-2", { "d-none" => !Setting.apiv3_cors_enabled? }],
              data: {
                target_name: "apiv3_cors_enabled",
                show_when_checked_target: "effect",
                show_when: "checked"
              }
            ) do |builder|
              CORSForm.new(builder)
            end
          end
        end

        sf.submit
      end
    end
  end
end
