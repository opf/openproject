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

module Storages::Admin
  class StorageAudienceInputForm < ApplicationForm
    form do |storage_form|
      storage_form.radio_button_group(name: :audience_configuration) do |group|
        group.radio_button(
          value: :idp,
          checked: idp?,
          label: I18n.t("storages.storage_audience.idp.label"),
          caption: I18n.t("storages.storage_audience.idp.helptext"),
          data: { action: "storages--storage-audience#hideAudienceInput", "storages--storage-audience-target": "idpRadio" }
        )

        group.radio_button(
          value: :manual,
          checked: !idp?,
          label: I18n.t("storages.storage_audience.manual.label"),
          caption: I18n.t("storages.storage_audience.manual.helptext"),
          data: { action: "storages--storage-audience#showAudienceInput" }
        )
      end

      storage_form.group(data: { "storages--storage-audience-target": "audienceInputWrapper" }) do |toggleable_group|
        toggleable_group.text_field(
          name: :storage_audience,
          label: I18n.t("activerecord.attributes.storages/nextcloud_storage.storage_audience"),
          required: true,
          caption: I18n.t("storages.instructions.nextcloud.storage_audience"),
          placeholder: I18n.t("storages.instructions.nextcloud.storage_audience_placeholder"),
          input_width: :large,
          data: { "storages--storage-audience-target": "audienceInput" },
          value: prefilled_audience
        )

        toggleable_group.text_field(
          name: :token_exchange_scope,
          label: I18n.t("activerecord.attributes.storages/nextcloud_storage.token_exchange_scope"),
          required: false,
          caption: I18n.t("storages.instructions.nextcloud.token_exchange_scope"),
          input_width: :large
        )
      end
    end

    private

    def idp?
      model.storage_audience == OpenIDConnect::UserToken::IDP_AUDIENCE
    end

    def prefilled_audience
      return "" if idp?

      model.storage_audience
    end
  end
end
