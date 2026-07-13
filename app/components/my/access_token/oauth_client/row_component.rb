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

module My
  module AccessToken
    module OAuthClient
      class RowComponent < OpPrimer::BorderBoxRowComponent
        def client_token
          model
        end

        def name
          render(Primer::Beta::Text.new(test_selector: "oauth-client-token-#{row.id}")) do
            client_token.oauth_client.integration.name
          end
        end

        def integration_type
          integration_class = client_token.oauth_client.integration&.class

          return I18n.t("my_account.access_tokens.oauth_client.unknown_integration") unless integration_class

          integration_class.model_name.human
        end

        def created_at
          helpers.format_time(client_token.created_at)
        end

        def expires_on
          return I18n.t(:label_never) if client_token.expires_in.blank?

          helpers.format_time(client_token.updated_at + client_token.expires_in.seconds)
        end

        def button_links
          [delete_link].compact
        end

        def delete_link
          render(Primer::Beta::IconButton.new(
                   icon: :trash,
                   scheme: :danger,
                   tag: :a,
                   href: my_access_token_remove_oauth_client_token_path(client_token),
                   "aria-label": t(:button_delete),
                   tooltip_direction: :w,
                   test_selector: "oauth-client-token-#{client_token.id}-remove",
                   data: {
                     turbo_method: :delete,
                     turbo_confirm: t(
                       "my_account.access_tokens.oauth_client.remove_token",
                       integration: client_token.oauth_client.integration.name
                     )
                   }
                 ))
        end
      end
    end
  end
end
