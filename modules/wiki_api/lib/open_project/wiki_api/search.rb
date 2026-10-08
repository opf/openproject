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

module OpenProject
  module WikiAPI
    # PostgreSQL full-text search over wiki pages.
    #
    # Uses a GIN index on `to_tsvector(config, title || ' ' || text)` where
    # `config` is read from the `OPENPROJECT_WIKI__API_TSVECTOR__CONFIG`
    # environment variable (see the migration that creates the index).
    # Defaults to the language-agnostic `simple` configuration so it works
    # in any locale out of the box; installations targeting a specific
    # language may set the variable to a matching PostgreSQL text search
    # config (e.g. `english`, `german`, `russian`) and re-run the migration.
    module Search
      DEFAULT_TS_CONFIG = "simple"

      module_function

      # @return [String] the configured PostgreSQL text search configuration.
      def ts_config
        ENV.fetch("OPENPROJECT_WIKI__API_TSVECTOR__CONFIG", DEFAULT_TS_CONFIG)
      end

      # Runs a full-text search over the given wiki's pages.
      #
      # @param wiki [Wiki]
      # @param query [String]
      # @param page [Integer] one-based page index (unused here, applied by
      #   the paginator in the representer)
      # @param per_page [Integer]
      # @return [ActiveRecord::Relation<WikiPage>] ordered by ts_rank DESC,
      #   then by updated_at DESC.
      def call(wiki:, query:, page: 1, per_page: 25) # rubocop:disable Lint/UnusedMethodArgument
        relation = WikiPage.where(wiki_id: wiki.id)
        return relation.none if query.blank?

        config = ts_config

        tsquery  = sanitize_sql("plainto_tsquery(?, ?)", config, query)
        tsvector = sanitize_sql(
          "to_tsvector(?, coalesce(wiki_pages.title, '') || ' ' || coalesce(wiki_pages.text, ''))",
          config
        )
        rank = "ts_rank(#{tsvector}, #{tsquery})"

        relation
          .select("wiki_pages.*, #{rank} AS search_rank")
          .where(Arel.sql("#{tsvector} @@ #{tsquery}"))
          .order(Arel.sql("search_rank DESC"))
          .order(updated_at: :desc)
      end

      def sanitize_sql(sql, *args)
        ActiveRecord::Base.send(:sanitize_sql_array, [sql, *args])
      end
    end
  end
end
