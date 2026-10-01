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
      module Internal
        module Queries
          class PageInfoForUrl < BaseQuery
            def call(input_data:, auth_strategy:)
              project_identifier, slug = match_url(input_data.url)
              return failure(code: :not_found) if project_identifier.nil?

              Adapters::Authentication[auth_strategy].call do |user|
                wiki = find_wiki(project_identifier:, user:)
                return failure(code: :not_found) if wiki.nil?

                wiki_page = find_page(wiki:, slug:, user:)
                return failure(code: :not_found) if wiki_page.nil?

                success(PageInfo.wiki_page_to_page_info(wiki_page, provider:))
              end
            end

            private

            def match_url(url)
              matcher = %r{https?://#{Regexp.escape host_name}/projects/([^/]+)/wiki/([^/]+)}
              match = matcher.match(url)
              return nil if match.nil?

              [match[1], match[2]]
            end

            def host_name = Setting.host_name

            def find_wiki(project_identifier:, user:)
              Project.visible(user).find_by(identifier: project_identifier)&.wiki
            end

            def find_page(wiki:, slug:, user:)
              wiki.pages.visible(user).find_by(slug:)
            end
          end
        end
      end
    end
  end
end
