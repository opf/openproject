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
    module API
      class RowComponent < OpPrimer::BorderBoxRowComponent
        def api_token
          model
        end

        def token_name
          if !api_token.respond_to?(:token_name) || api_token.token_name.nil?
            t(:static_token_name, scope: i18n_token_scope)
          else
            api_token.token_name
          end
        end

        def created_at
          helpers.format_time(api_token.created_at)
        end

        def expires_on
          return I18n.t("my_account.access_tokens.indefinite_expiration") unless expires?

          date = helpers.format_date(api_token.expires_on_date)
          return date unless api_token.expired?

          render(Primer::Beta::Text.new(color: :danger, font_weight: :bold)) do
            concat(render(Primer::Beta::Octicon.new(:alert, mr: 1)))
            concat(I18n.t("my_account.access_tokens.expired_on", date:))
          end
        end

        def button_links
          [delete_link].compact
        end

        def delete_link
          render(Primer::Beta::IconButton.new(
                   icon: :trash,
                   scheme: :danger,
                   tag: :a,
                   href: delete_path,
                   "aria-label": t(:button_delete),
                   tooltip_direction: :w,
                   test_selector: "api-token-revoke",
                   data: {
                     turbo_method: :delete,
                     turbo_confirm: t("my_account.access_tokens.simple_revoke_confirmation")
                   }
                 ))
        end

        private

        def expires?
          api_token.is_a?(Token::Expirable) && api_token.expires_on.present?
        end

        def delete_path
          case model
          when Token::API then my_access_token_revoke_api_key_path(api_token.id)
          when Token::ICalMeeting then my_access_token_revoke_ical_meeting_token_path(api_token.id)
          when Token::RSS then revoke_rss_key_my_access_tokens_path(api_token.id)
          end
        end

        def i18n_token_scope
          [:my_account, :access_tokens, api_token.class.model_name.i18n_key]
        end
      end
    end
  end
end
