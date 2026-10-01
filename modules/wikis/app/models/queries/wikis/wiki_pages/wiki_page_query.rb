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

module Queries
  module Wikis
    module WikiPages
      class WikiPageQuery
        include BaseQuery
        include UnpersistedQuery

        # Static queries selectable via the query_id param, mapping each id
        # to the scope narrowing it stands for. The order is the order of the
        # entries in the sidebar.
        STATIC_QUERIES = {
          "all" => ->(scope) { scope },
          "main" => ->(scope) { scope.where(parent_id: nil) }
        }.freeze
        DEFAULT_QUERY = "all"

        def self.normalized_query_id(value)
          STATIC_QUERIES.key?(value.to_s) ? value.to_s : DEFAULT_QUERY
        end

        def self.static_queries
          STATIC_QUERIES.keys.map do |query_id|
            new.tap { |query| query.query_id = query_id }
          end
        end

        def query_id
          @query_id || DEFAULT_QUERY
        end

        def query_id=(value)
          @query_id = self.class.normalized_query_id(value)
        end

        def name
          I18n.t("wikis.index.queries.#{query_id}")
        end

        def default_scope
          STATIC_QUERIES.fetch(query_id).call(
            ::WikiPage
              .joins(wiki: :project)
              .merge(::Project.allowed_to(user, :view_wiki_pages))
              .select("wiki_pages.*", <<~SQL.squish)
                (SELECT COUNT(*) FROM wiki_pages children
                 WHERE children.parent_id = wiki_pages.id) AS sub_pages_count
              SQL
              .order(updated_at: :desc)
          )
        end
      end
    end
  end
end
