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
      class TableComponent < OpPrimer::BorderBoxTableComponent
        columns :name, :calendar, :project, :created_at, :expires_on
        main_column :name
        mobile_labels :created_at, :expires_on

        def headers
          [
            [:name, { caption: I18n.t("attributes.name") }],
            [:calendar, { caption: Token::ICal.human_attribute_name(:calendar) }],
            [:project, { caption: WorkPackage.human_attribute_name(:project) }],
            [:created_at, { caption: User.human_attribute_name(:created_at) }],
            [:expires_on, { caption: I18n.t("my_account.access_tokens.headers.expiration") }]
          ]
        end

        def mobile_title
          I18n.t("my_account.access_tokens.ical.table_title")
        end

        def row_class
          RowComponent
        end

        def has_actions?
          true
        end

        def blank_title
          I18n.t("my_account.access_tokens.ical.blank_title")
        end

        def blank_description
          I18n.t("my_account.access_tokens.ical.blank_description")
        end

        def blank_icon
          nil
        end
      end
    end
  end
end
