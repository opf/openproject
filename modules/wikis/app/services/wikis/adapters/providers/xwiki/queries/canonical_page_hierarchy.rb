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
          class CanonicalPageHierarchy < BaseQuery
            include Concerns::XWikiRequest
            include Concerns::XWikiPageQueries

            class << self
              def json_to_page_hierarchy(data, provider:)
                *ancestors, page = data

                Results::PageHierarchy.new(
                  wiki: json_to_wiki(page, provider:),
                  page: StablePageInfo.json_to_page_info(page, provider:),
                  ancestors: ancestors.reverse.map { StablePageInfo.json_to_page_info(it, provider:) }
                )
              end

              def json_to_wiki(page, provider:)
                Results::Wiki.new(
                  identifier: fetch_json(page, "hierarchy", "items", 0, "name"),
                  provider:,
                  name: fetch_json(page, "hierarchy", "items", 0, "label"),
                  href: fetch_json(page, "hierarchy", "items", 0, "url")
                )
              end
            end

            def call(input_data:, auth_strategy:)
              canonical_page_info(identifier: input_data.identifier, auth_strategy:).bind do |page_info|
                perform_request(page_info.identifier, auth_strategy:) do |data|
                  success(self.class.json_to_page_hierarchy(data, provider:))
                end
              end
            end

            def perform_request(identifier, auth_strategy:, &)
              authenticated(auth_strategy) do |http|
                handle_response(
                  http.get(rest_url("openproject/documents/#{identifier}/ancestors")),
                  &
                )
              end
            end
          end
        end
      end
    end
  end
end
