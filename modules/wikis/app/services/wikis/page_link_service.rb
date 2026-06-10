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
  class PageLinkService
    include Dry::Monads[:result]

    def count(linkable)
      relation_page_links = Provider.enabled.sum { |provider| relation_page_links_for(provider:, linkable:).size }

      relation_page_links +
        inline_page_link_infos_for(linkable:).size +
        referencing_wiki_page_infos_for(linkable:).size
    end

    def relation_page_links_for(provider:, linkable:)
      Adapters::Input::RelationPageLinks.build(linkable:).bind do |input_data|
        provider.auth_strategy_for(User.current).bind do |auth_strategy|
          provider.resolve("queries.relation_page_links")
                  .call(input_data:, auth_strategy:)
                  .either(
                    ->(page_links) { page_links },
                    -> { [] }
                  )
        end
      end
    end

    def inline_page_link_infos_for(linkable:)
      InlinePageLink.where(linkable:)
                    .order(created_at: :asc)
                    .map { page_info(provider: it.provider, identifier: it.identifier) }
    end

    def referencing_wiki_page_infos_for(linkable:)
      referenced_in = []

      Adapters::Input::ReferencingPages.build(linkable:).bind do |input|
        Provider.enabled.each do |provider|
          provider.auth_strategy_for(User.current).bind do |auth_strategy|
            provider.resolve("queries.referencing_pages")
                    .call(input_data: input, auth_strategy:)
                    # Only return page infos for successful results
                    .fmap { referenced_in.concat(it) }
          end
        end
      end

      referenced_in
    end

    private

    def page_info(provider:, identifier:)
      Adapters::Input::PageInfo.build(identifier:).bind do |input|
        provider.auth_strategy_for(User.current).bind do |auth_strategy|
          provider.resolve("queries.page_info").call(input_data: input, auth_strategy:)
        end
      end
    end

    def page_title_service
      @page_title_service ||= PageTitleService.new
    end
  end
end
