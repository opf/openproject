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

            class << self
              def json_to_page_hierarchy(data, provider:)
                Results::PageHierarchy.new(
                  wiki: json_to_wiki(data, provider:),
                  page: StablePageInfo.json_to_page_info(data, provider:),
                  ancestors: json_to_ancestors(data, provider:)
                )
              end

              def json_to_wiki(data, provider:)
                Results::Wiki.new(
                  identifier: fetch_json(data, "hierarchy", "items", 0, "name"),
                  provider:,
                  name: fetch_json(data, "hierarchy", "items", 0, "label"),
                  href: fetch_json(data, "hierarchy", "items", 0, "url")
                )
              end

              def json_to_ancestors(data, provider:)
                page_title = fetch_json(data, "title")

                ancestors = fetch_json(data, "hierarchy", "items").filter do |item|
                  next false unless fetch_json(item, "type") == "space"

                  fetch_json(item, "label") != page_title
                end

                ancestors.reverse.map do |item|
                  Results::PageInfo.new(
                    # FIXME: We need a real id here
                    identifier: fetch_json(item, "name"),
                    title: fetch_json(item, "label"),
                    href: fetch_json(item, "url"),
                    provider:
                  )
                end
              end
            end

            def call(input_data:, auth_strategy:)
              ref = CanonicalPageReference.parse(input_data.identifier)
              return failure(code: :not_found) unless ref

              perform_request(ref, auth_strategy:) do |data|
                success(self.class.json_to_page_hierarchy(data, provider:))
              end
            end

            def perform_request(reference, auth_strategy:, &)
              authenticated(auth_strategy) do |http|
                handle_response(
                  http.get(rest_url("openproject/documents", query: { docRef: reference.to_s })),
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
