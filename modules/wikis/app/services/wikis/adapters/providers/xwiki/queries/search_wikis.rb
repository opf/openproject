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
          class SearchWikis < BaseQuery
            include Concerns::XWikiRequest

            MAXIMUM_RESULTS = 10

            def call(input_data:, auth_strategy:)
              authenticated(auth_strategy) do |http|
                handle_response(http.get(rest_url("wikis"))) do |json|
                  success(matching_wikis(fetch_json(json, "wikis"), input_data.query))
                end
              end
            end

            private

            def matching_wikis(wikis, query)
              wikis.select { fetch_json(it, "name").downcase.include?(query.downcase) }
                   .first(MAXIMUM_RESULTS)
                   .map { json_to_wiki(it) }
            end

            def json_to_wiki(wiki)
              name = fetch_json(wiki, "name")

              Results::Wiki.new(identifier: name, provider:, name:, href: home_url)
            end

            def home_url
              "#{provider.url.chomp('/')}/bin/view/Main/"
            end
          end
        end
      end
    end
  end
end
