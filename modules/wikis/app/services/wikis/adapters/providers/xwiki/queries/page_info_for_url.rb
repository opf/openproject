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
          class PageInfoForUrl < BaseQuery
            def call(input_data:, auth_strategy:)
              return failure(code: :not_found) unless input_data.url.start_with?(provider.url)

              path = extract_path(input_data.url)

              wiki_path, space_path = path.split("/view/", 2)
              return failure(code: :not_found) if space_path.nil?

              wiki = wiki_name(wiki_path)
              parts = CGI.unescape(space_path).split("/")

              find_page_info(wiki:, parts:, auth_strategy:)
            end

            private

            def extract_path(uri)
              uri = URI.parse(uri)
              uri.query = nil
              uri.fragment = nil
              uri.to_s.delete_prefix(provider.url).delete_prefix("/")
            end

            def wiki_name(wiki_path)
              # The default wiki name seems to be xwiki and it builts entirely different pathes than
              # other wikis
              return "xwiki" if wiki_path == "bin"

              wiki_path.delete_prefix("wiki/")
            end

            def find_page_info(wiki:, parts:, auth_strategy:)
              canonical_page_info(identifier: space_page_id(wiki, parts), auth_strategy:).or do |error|
                next Failure(error) unless error.code == :not_found

                canonical_page_info(identifier: space_only_id(wiki, parts), auth_strategy:)
              end
            end

            def space_page_id(wiki, parts)
              *spaces, page = parts
              "#{wiki}:#{spaces.join('.')}.#{page}"
            end

            def space_only_id(wiki, spaces)
              # if the path does not contain the page name, we guess that it's called "WebHome"
              "#{wiki}:#{spaces.join('.')}.WebHome"
            end

            def canonical_page_info(identifier:, auth_strategy:)
              Input::PageInfo.build(identifier:).bind do |input_data|
                Internal::CanonicalPageInfo.new(model: provider).call(input_data:, auth_strategy:)
              end
            end
          end
        end
      end
    end
  end
end
