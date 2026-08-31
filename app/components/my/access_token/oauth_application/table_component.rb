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
    module OAuthApplication
      class TableComponent < OpPrimer::BorderBoxTableComponent
        columns :name, :active_tokens, :last_refreshed_at
        main_column :name
        mobile_labels :active_tokens, :last_refreshed_at

        def headers
          [
            [:name, { caption: I18n.t("attributes.name") }],
            [:active_tokens, { caption: I18n.t("my_account.access_tokens.oauth_application.active_tokens") }],
            [:last_refreshed_at, { caption: I18n.t("my_account.access_tokens.oauth_application.last_refreshed_at") }]
          ]
        end

        def mobile_title
          I18n.t("my_account.access_tokens.oauth_application.table_title")
        end

        def row_class
          RowComponent
        end

        def has_actions?
          true
        end

        def blank_title
          I18n.t("my_account.access_tokens.oauth_application.blank_title")
        end

        def blank_description
          I18n.t("my_account.access_tokens.oauth_application.blank_description")
        end

        def blank_icon
          nil
        end
      end
    end
  end
end
