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

module Saml
  module Providers
    class TableComponent < ::OpPrimer::BorderBoxTableComponent
      columns :name, :users, :creator, :created_at

      mobile_columns :name, :users

      mobile_labels :users

      main_column :name

      def initial_sort
        %i[id asc]
      end

      def sortable?
        false
      end

      def empty_row_message
        I18n.t "saml.providers.no_results_table"
      end

      def mobile_title
        I18n.t("saml.providers.plural")
      end

      def headers
        [
          [:name, { caption: I18n.t("attributes.name") }],
          [:users, { caption: I18n.t(:label_user_plural) }],
          [:creator, { caption: I18n.t("js.label_created_by") }],
          [:created_at, { caption: Saml::Provider.human_attribute_name(:created_at) }]
        ]
      end

      def blank_title
        I18n.t("saml.providers.label_empty_title")
      end

      def blank_description
        I18n.t("saml.providers.label_empty_description")
      end

      def blank_icon
        :key
      end
    end
  end
end
