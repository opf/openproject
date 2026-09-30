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
    module API
      class TableComponent < OpPrimer::BorderBoxTableComponent
        columns :token_name, :created_at, :expires_on
        main_column :token_name
        mobile_labels :created_at, :expires_on

        def initialize(title:, token_type:, **)
          super(**)

          @title = title
          @token_type = token_type
        end

        def headers
          [
            [:token_name, { caption: I18n.t("attributes.name") }],
            [:created_at, { caption: User.human_attribute_name(:created_at) }],
            [:expires_on, { caption: I18n.t("my_account.access_tokens.headers.expiration") }]
          ]
        end

        def mobile_title
          @title
        end

        def row_class
          RowComponent
        end

        def has_actions?
          true
        end

        def blank_title
          I18n.t(:blank_title, scope: i18n_token_scope)
        end

        def blank_description
          I18n.t(:blank_description, scope: i18n_token_scope)
        end

        def blank_icon
          nil
        end

        private

        def i18n_token_scope
          [:my_account, :access_tokens, @token_type.model_name.i18n_key]
        end
      end
    end
  end
end
