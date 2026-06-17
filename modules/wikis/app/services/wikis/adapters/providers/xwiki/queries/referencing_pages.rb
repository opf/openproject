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
          # Fetches all XWiki pages that reference a work package, combining two XWiki endpoints:
          # - /openproject/links/workPackages
          # - /openproject/mentions
          # Results are merged and deduplicated. Either endpoint failing fails the whole query.
          class ReferencingPages < BaseQuery
            include Concerns::XWikiRequest
            include Concerns::XWikiPageQueries

            MAXIMUM_RESULTS = 25

            def call(input_data:, auth_strategy:)
              authenticated(auth_strategy) do |http|
                fetch_reference_ids(http, input_data).bind do |reference_ids|
                  fetch_mention_ids(http, input_data).bind do |mention_ids|
                    ids = (reference_ids + mention_ids).uniq
                    success(ids.map { canonical_page_info(identifier: it, auth_strategy:) })
                  end
                end
              end
            end

            private

            def fetch_reference_ids(http, input_data)
              fetch_page_ids(http, rest_url("openproject/links/workPackages/#{input_data.linkable.id}"),
                             params: { number: MAXIMUM_RESULTS })
            end

            def fetch_mention_ids(http, input_data)
              fetch_page_ids(http, rest_url("openproject/mentions"), params: { workPackage: input_data.linkable.id })
            end

            def fetch_page_ids(http, url, params:)
              handle_response(http.get(url, params:)) do |data|
                success(fetch_json(data, "searchResults").map { fetch_json(it, "id") }.uniq)
              end
            end
          end
        end
      end
    end
  end
end
