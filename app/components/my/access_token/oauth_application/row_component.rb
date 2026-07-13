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
    module OAuthApplication
      class RowComponent < OpPrimer::BorderBoxRowComponent
        def oauth_application
          model.first
        end

        def oauth_application_tokens
          model.last
        end

        def name
          render(Primer::Beta::Text.new(test_selector: "oauth-application-#{oauth_application.id}-name")) do
            oauth_application.name
          end
        end

        def active_token_count
          oauth_application_tokens.count { |t| !t.expired? && !t.revoked? }
        end

        def active_tokens
          render(Primer::Beta::Text.new(test_selector: "oauth-application-#{oauth_application.id}-active-tokens")) do
            active_token_count.to_s
          end
        end

        def last_refreshed_at
          return "—" if oauth_application_tokens.empty?

          helpers.format_time(oauth_application_tokens.max_by(&:created_at).created_at)
        end

        def button_links
          [delete_link].compact
        end

        def delete_link
          render(Primer::Beta::IconButton.new(
                   icon: :trash,
                   scheme: :danger,
                   tag: :a,
                   href: revoke_my_oauth_application_path(application_id: oauth_application.id),
                   "aria-label": t(:button_delete),
                   tooltip_direction: :w,
                   test_selector: "oauth-token-row-#{oauth_application.id}-revoke",
                   data: {
                     turbo_method: :post,
                     turbo_confirm: t(
                       "oauth.confirm_revoke_my_application",
                       count: active_token_count
                     )
                   }
                 ))
        end
      end
    end
  end
end
