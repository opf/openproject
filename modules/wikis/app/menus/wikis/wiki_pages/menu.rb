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

module Wikis
  module WikiPages
    class Menu < Submenu
      def initialize(params:, project: nil)
        super(view_type: nil, project:, params:)
      end

      def menu_items
        [
          OpenProject::Menu::MenuGroup.new(header: nil, children: top_level_menu_items)
        ]
      end

      def top_level_menu_items
        Queries::Wikis::WikiPages::WikiPageQuery.static_queries.map do |query|
          menu_item(title: query.name,
                    query_params: { query_id: query.query_id },
                    selected: query.query_id == current_query_id)
        end
      end

      private

      def current_query_id
        Queries::Wikis::WikiPages::WikiPageQuery.normalized_query_id(params[:query_id])
      end

      def query_path(query_params)
        wiki_pages_path(**query_params)
      end
    end
  end
end
