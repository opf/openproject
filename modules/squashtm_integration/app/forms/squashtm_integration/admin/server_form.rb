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

module SquashTMIntegration
  module Admin
    class ServerForm < ApplicationForm
      form do |f|
        f.text_field(
          name: :base_url,
          label: attribute_name(:base_url),
          caption: I18n.t("squashtm_integration.admin.server_form.base_url_caption"),
          placeholder: "https://squashtm.example.com/squash",
          required: true,
          type: :url,
          input_width: :large
        )

        # The stored token is never rendered back; a blank submission keeps it.
        f.text_field(
          name: :api_token,
          label: attribute_name(:api_token),
          caption: api_token_caption,
          placeholder: (I18n.t("squashtm_integration.admin.server_form.api_token_placeholder_stored") if model.api_token_stored?),
          value: nil,
          type: :password,
          autocomplete: "off",
          required: !model.api_token_stored?,
          input_width: :large
        )

        f.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
      end

      private

      def api_token_caption
        key = model.api_token_stored? ? "api_token_caption_stored" : "api_token_caption"
        I18n.t("squashtm_integration.admin.server_form.#{key}")
      end
    end
  end
end
