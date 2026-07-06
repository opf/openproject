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
          class PageHierarchy < BaseQuery
            class << self
              def wiki_page_to_page_hierarchy(wiki_page, provider:)
                Results::PageHierarchy.new(
                  wiki: wiki_to_adapter_wiki(wiki_page.wiki, provider:),
                  page: PageInfo.wiki_page_to_page_info(wiki_page, provider:),
                  ancestors: wiki_page.ancestors.map { PageInfo.wiki_page_to_page_info(it, provider:) }
                )
              end

              def wiki_to_adapter_wiki(wiki, provider:)
                Results::Wiki.new(
                  identifier: wiki.id.to_s,
                  provider:,
                  name: wiki.project.name,
                  # FIXME: internal wiki currently has no notion of a single root page, nor an official "entrypoint"
                  href: url_for(only_path: true,
                                controller: "/wiki",
                                action: "show",
                                project_id: wiki.project.identifier,
                                id: WikiPage.main_pages(wiki).first.slug)
                )
              end

              private

              delegate :url_for, to: :url_helpers

              def url_helpers
                @url_helpers ||= OpenProject::StaticRouting::StaticRouter.new.url_helpers
              end
            end

            def call(input_data:, auth_strategy:)
              Adapters::Authentication[auth_strategy].call do |user|
                wiki_page = WikiPage.visible(user).find_by(id: input_data.identifier)
                return failure(code: :not_found) if wiki_page.nil?

                success(self.class.wiki_page_to_page_hierarchy(wiki_page, provider:))
              end
            end
          end
        end
      end
    end
  end
end
