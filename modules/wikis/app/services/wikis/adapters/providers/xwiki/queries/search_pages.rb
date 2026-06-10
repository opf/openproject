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
  module Adapters
    module Providers
      module XWiki
        module Queries
          class SearchPages < BaseQuery
            include Concerns::XWikiQuery
            include Concerns::XWikiPageQueries

            # Limiting result size rather strictly, because each result will cause another HTTP call to XWiki, this does not
            # scale well. A stricter limit improves the worst case latency.
            MAXIMUM_RESULTS = 20

            def call(input_data:, auth_strategy:)
              query = { q: "\"#{escape_quotes input_data.query}\"", number: MAXIMUM_RESULTS }

              authenticated(auth_strategy) do |http|
                handle_response(http.get(rest_url("wikis/query", query:))) do |json|
                  success(
                    fetch_json(json, "searchResults")
                      .uniq { |r| fetch_json(r, "id") }
                      .map do |r|
                        result = canonical_page_info(identifier: fetch_json(r, "id"), auth_strategy:)
                        return result if result.failure?

                        result.value!
                      end
                  )
                end
              end
            end

            private

            def escape_quotes(string)
              string.gsub("\\", "\\\\").gsub('"', '\"')
            end
          end
        end
      end
    end
  end
end
