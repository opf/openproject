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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  class ConnectionForm < ApplicationForm
    form do |f|
      f.check_box(
        name: :enabled,
        label: LlmConnection.human_attribute_name(:enabled),
        caption: I18n.t("admin.llm_connections.form.enabled_caption")
      )

      f.select_list(
        name: :api_format,
        label: LlmConnection.human_attribute_name(:api_format),
        caption: I18n.t("admin.llm_connections.form.api_format_caption"),
        include_blank: false,
        input_width: :medium
      ) do |select|
        # Only formats a request can actually be sent in. The contract rejects
        # the rest as a backstop, but they should not be offered in the first place.
        Llm::Adapters::FORMATS.select { |format| Llm::Session.supports?(format) }.each do |format|
          select.option(value: format, label: I18n.t("llm.api_formats.#{format}"))
        end
      end

      f.text_field(
        name: :base_url,
        label: LlmConnection.human_attribute_name(:base_url),
        caption: I18n.t("admin.llm_connections.form.base_url_caption"),
        placeholder: "https://example.com/v1",
        required: true,
        type: :url,
        input_width: :large
      )

      f.text_field(
        name: :api_key,
        label: LlmConnection.human_attribute_name(:api_key),
        caption: api_key_caption,
        # The stored key is never sent to the browser. A blank submission means
        # "keep the current key", handled in the controller.
        value: nil,
        placeholder: api_key_placeholder,
        type: :password,
        autocomplete: "off",
        input_width: :large,
        data: { "admin--llm-connection-form-target": "secretInput" }
      )

      f.submit(
        name: :submit,
        label: submit_label,
        scheme: :primary,
        data: { "admin--llm-connection-form-target": "submitButton" }
      )
    end

    private

    def submit_label
      model.persisted? ? I18n.t(:button_save) : I18n.t("admin.llm_connections.form.button_connect")
    end

    def api_key_caption
      key = model.persisted? && model.api_key.present?
      I18n.t("admin.llm_connections.form.api_key_caption#{'_stored' if key}")
    end

    def api_key_placeholder
      "••••••••••••••••" if model.api_key.present?
    end
  end
end
