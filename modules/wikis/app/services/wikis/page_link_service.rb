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
      relation_page_link_count(linkable) +
        inline_page_link_infos_for(linkable:).size +
        wiki_page_reference_count(linkable)
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
      wiki_page_infos_for(
        linkable:,
        input_class: Adapters::Input::ReferencingPages,
        query_name: "queries.referencing_pages"
      )
    end

    def mentioning_wiki_page_infos_for(linkable:)
      wiki_page_infos_for(
        linkable:,
        input_class: Adapters::Input::MentioningPages,
        query_name: "queries.mentioning_pages"
      )
    end

    private

    def relation_page_link_count(linkable)
      Provider.enabled.sum { |provider| relation_page_links_for(provider:, linkable:).size }
    end

    def wiki_page_reference_count(linkable)
      (referencing_wiki_page_infos_for(linkable:) + mentioning_wiki_page_infos_for(linkable:))
        .uniq { |r| r.success? ? r.value!.identifier : r.object_id }
        .size
    end

    def wiki_page_infos_for(linkable:, input_class:, query_name:)
      results = []

      input_class.build(linkable:).bind do |input|
        Provider.enabled.each do |provider|
          query = resolve_query(provider, query_name)
          next if query.nil?

          provider.auth_strategy_for(User.current).bind do |auth_strategy|
            query.call(input_data: input, auth_strategy:)
                 .fmap { results.concat(it) }
          end
        end
      end

      results
    end

    def resolve_query(provider, name)
      provider.resolve(name)
    rescue Adapters::Registry::OperationNotSupported
      nil
    end

    def page_info(provider:, identifier:)
      Adapters::Input::PageInfo.build(identifier:).bind do |input|
        provider.auth_strategy_for(User.current).bind do |auth_strategy|
          provider.resolve("queries.page_info").call(input_data: input, auth_strategy:)
        end
      end
    end
  end
end
