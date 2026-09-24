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

module OpenIDConnect
  module Providers
    class GroupMappingForm < BaseForm
      include Redmine::I18n

      class << self
        def form_data
          {
            controller: "openid-connect--group-sync-form",
            action: "openid-connect--match-preview-dialog:submitted->openid-connect--group-sync-form#previewSubmitted",
            "openid-connect--group-sync-form-openid-connect--match-preview-dialog-outlet":
              "#openid-connect--group-match-preview-dialog"
          }
        end
      end

      form do |f|
        f.check_box(
          name: :sync_groups,
          label: OpenIDConnect::Provider.human_attribute_name(:sync_groups),
          caption: I18n.t("openid_connect.instructions.group_sync"),
          disabled: provider.seeded_from_env?,
          data: {
            action: "openid-connect--group-sync-form#updateFormInputs",
            "openid-connect--group-sync-form-target": "enabledCheckbox"
          }
        )

        f.group(data: { "openid-connect--group-sync-form-target": "inputsWrapper" }) do |group|
          group.text_field(
            name: :groups_claim,
            label: OpenIDConnect::Provider.human_attribute_name(:groups_claim),
            caption: I18n.t("openid_connect.instructions.groups_claim"),
            required: true,
            input_width: :large,
            disabled: provider.seeded_from_env?
          )

          group.html_content do
            render(Primer::Beta::Text.new) { helpers.t("openid_connect.instructions.group_regexes_detail_html") }
          end

          group.text_area(
            name: :group_regexes,
            rows: 5,
            validation_message: custom_validation_message_for(:group_regexes),
            label: OpenIDConnect::Provider.human_attribute_name(:group_regexes),
            caption: link_translate("openid_connect.instructions.group_regexes",
                                    links: { docs_url: %i[sysadmin_docs oidc_groups] },
                                    external: true),
            data: {
              "openid-connect--group-sync-form-target": "regexpInput"
            },
            disabled: provider.seeded_from_env?,
            required: false,
            input_width: :large,
            value: model.group_regexes.join("\n")
          )

          group.html_content do
            render(
              ::OpPrimer::FlashComponent.new(icon: :info, dismiss_scheme: :none, unique_key: "test_regex_patterns")
            ) do |banner|
              banner.with_action_content { render(OpenIDConnect::Groups::MatchPreviewDialogComponent.new) }

              I18n.t("openid_connect.instructions.group_regexes_testing")
            end
          end
        end
      end

      private

      def custom_validation_message_for(attribute)
        return unless model.errors.has_key?(attribute)

        model.errors[attribute].to_sentence
      end
    end
  end
end
