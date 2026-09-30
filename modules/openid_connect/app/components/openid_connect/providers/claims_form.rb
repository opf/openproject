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

module OpenIDConnect
  module Providers
    class ClaimsForm < BaseForm
      include Redmine::I18n

      form do |f|
        f.text_area(
          name: :claims,
          rows: 10,
          label: OpenIDConnect::Provider.human_attribute_name(:claims),
          caption: link_translate(
            "openid_connect.instructions.claims",
            links: { docs_url: %i[sysadmin_docs oidc_claims] }
          ),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large,
          value: pretty_claims
        )

        f.text_field(
          name: :acr_values,
          label: OpenIDConnect::Provider.human_attribute_name(:acr_values),
          caption: link_translate(
            "openid_connect.instructions.acr_values",
            links: { docs_url: %i[sysadmin_docs oidc_acr_values] }
          ),
          disabled: provider.seeded_from_env?,
          required: false,
          input_width: :large
        )
      end

      private

      def pretty_claims
        claims = model.claims || ""
        JSON.pretty_generate(JSON.parse(claims))
      rescue JSON::ParserError
        claims
      end
    end
  end
end
