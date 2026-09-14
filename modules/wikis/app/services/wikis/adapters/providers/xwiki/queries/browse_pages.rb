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
          class BrowsePages < BaseQuery
            include Concerns::XWikiRequest

            def call(auth_strategy:, input_data:)
              authenticated(auth_strategy) do |http|
                pages = if input_data.parent_identifier.blank?
                          get_wikis_and_root_pages(http)
                        else
                          get_children_pages(http, input_data.parent_identifier)
                        end

                pages.fmap { build_page_hierarchy(it, auth_strategy) }
              end
            end

            private

            def build_page_hierarchy(pages, auth_strategy)
              pages.filter_map do |page_json|
                Input::PageHierarchy.build(identifier: fetch_json(page_json, "id")).bind do |input_data|
                  CanonicalPageHierarchy.new(model: provider).call(input_data:, auth_strategy:).value_or(nil)
                end
              end
            end

            def get_children_pages(http, parent_identifier)
              get_parent_canonical_id(http, parent_identifier).fmap { |parent_id| get_children(parent_id, http) }
            end

            def get_parent_canonical_id(http, identifier)
              handle_response(http.get(rest_url("/openproject/documents/#{identifier}"))) do |page|
                Success("#{fetch_json(page, 'wiki')}:#{fetch_json(page, 'fullName')}")
              end
            end

            def get_children(parent_identifier, http)
              CanonicalPageReference.parse(parent_identifier) => { wiki:, spaces:, page: }
              space_segment = spaces.map { "/spaces/#{CGI.escape(it)}" }.join

              request_url = rest_url("/wikis/#{wiki}/#{space_segment}/pages/#{page}/children",
                                     query: { hierarchy: "nestedpages" })

              handle_response(http.get(request_url)) do |children|
                fetch_json(children, "pageSummaries")
              end
            end

            def get_wikis_and_root_pages(http)
              get_wikis(http).fmap { |wikis_json| build_wikis(wikis_json) }.fmap { |wikis| get_wiki_children(wikis, http) }
            end

            def get_wikis(http)
              handle_response(http.get(rest_url("/wikis"))) { Success(fetch_json(it, "wikis")) }
            end

            def build_wikis(wikis_json)
              wikis_json.map do |wiki|
                Results::Wiki.new(identifier: fetch_json(wiki, "id"), name: fetch_json(wiki, "name"), href: nil, provider:)
              end
            end

            def get_wiki_children(wikis, http)
              wikis.flat_map do |wiki|
                request_url = rest_url("/wikis/#{wiki.identifier}/children", query: { hierarchies: "nestedpages" })
                handle_response(http.get(request_url)) do |children|
                  fetch_json(children, "pageSummaries")
                end
              end
            end
          end
        end
      end
    end
  end
end
