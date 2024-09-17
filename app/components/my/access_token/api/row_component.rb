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

module My
  module AccessToken
    module API
      class RowComponent < ::RowComponent
        def api_token
          model
        end

        def token_name
          if api_token.token_name.nil?
            t("my_account.access_tokens.api.static_token_name")
          else
            api_token.token_name
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
          link_to "",
                  {
                    controller: :my,
                    action: "revoke_api_key",
                    token_id: api_token.id
                  },
                  method: :delete,
                  data: { confirm: t("my_account.access_tokens.simple_revoke_confirmation"), test_selector: "api-token-revoke" },
                  class: "icon icon-delete"
        end
      end
    end
  end
end
