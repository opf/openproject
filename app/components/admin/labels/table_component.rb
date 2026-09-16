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

module Admin
  module Labels
    class TableComponent < OpPrimer::BorderBoxTableComponent
      options :query

      columns :name, :usage
      main_column :name
      mobile_columns :name, :usage
      mobile_labels :usage

      def has_actions? = true

      def headers
        [
          [:name,  { caption: t(".headers.name") }],
          [:usage, { caption: t(".headers.usage") }]
        ]
      end

      def mobile_title = t(:label_label_plural)

      def filtered?
        query.find_active_filter(:name).present?
      end

      def blank_title
        filtered? ? t(".no_matches.title") : t(".blank_slate.title")
      end

      def blank_description
        filtered? ? t(".no_matches.description") : t(".blank_slate.description")
      end

      def blank_icon
        filtered? ? :search : :tag
      end

      def pagination_params = { params: { action: "index" } }
    end
  end
end
