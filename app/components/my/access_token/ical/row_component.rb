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

module My
  module AccessToken
    module ICal
      class RowComponent < OpPrimer::BorderBoxRowComponent
        def api_token
          model
        end

        def name
          render(Primer::Beta::Text.new(test_selector: "ical-token-#{api_token.id}-name")) do
            api_token.ical_token_query_assignment.name
          end
        end

        def calendar
          render(
            Primer::Beta::Link.new(
              href: project_calendar_path(id: api_token.query.id, project_id: api_token.query.project_id),
              test_selector: "ical-token-#{api_token.id}-query-name"
            )
          ) { api_token.query.name }
        end

        def project
          render(Primer::Beta::Text.new(test_selector: "ical-token-#{api_token.id}-project-name")) do
            api_token.query.project.name
          end
        end

        def created_at
          helpers.format_time(api_token.created_at)
        end

        def expires_on
          I18n.t("my_account.access_tokens.indefinite_expiration")
        end

        def button_links
          [delete_link].compact
        end

        def delete_link
          render(Primer::Beta::IconButton.new(
                   icon: :trash,
                   scheme: :danger,
                   tag: :a,
                   href: my_access_token_revoke_ical_token_path(access_token_id: api_token.id),
                   "aria-label": t(:button_delete),
                   tooltip_direction: :w,
                   test_selector: "ical-token-#{api_token.id}-revoke",
                   data: {
                     turbo_method: :delete,
                     turbo_confirm: t("my_account.access_tokens.simple_revoke_confirmation")
                   }
                 ))
        end
      end
    end
  end
end
