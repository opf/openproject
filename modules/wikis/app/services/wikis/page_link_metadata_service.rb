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
  class PageLinkMetadataService
    # @param page_links [ActiveRecord::Relation<Wikis::PageLink>]
    def initialize(page_links)
      @result = ServiceResult.success(errors: ActiveModel::Errors.new(self))
      @relation = page_links
    end

    # @return [ServiceResult<ActiveRecord::Relation<Wikis::PageLink>]
    def call
      metadata = relation.group_by(&:provider).flat_map do |provider, page_links|
        build_inputs(page_links).filter_map do |(page_link_id, input_data)|
          request_page_info(input_data, provider).either(->(info) { [page_link_id, info.title] }, ->(*) {})
        end
      end

      @result.result = enrich_models(metadata)
      @result
    end

    private

    attr_reader :relation

    def request_page_info(input_data, provider)
      provider.auth_strategy_for(User.current).bind do |auth_strategy|
        provider.resolve("queries.page_info").call(input_data:, auth_strategy:)
      end
    end

    def build_inputs(page_links)
      page_links.filter_map do |page_link|
        [page_link.id, Adapters::Input::PageInfo.build(identifier: page_link.identifier).value_or(nil)]
      end
    end

    def enrich_models(metadata)
      variable_placeholders = Array.new(metadata.size, "(?,?)").join(",")
      join_string = <<~SQL.squish
        LEFT JOIN (VALUES #{variable_placeholders}) AS metadata(page_link_id, title)
          ON metadata.page_link_id = wiki_page_links.id
      SQL

      join_expression = OpenProject::SqlSanitization.sanitize(join_string, *metadata.flatten)

      relation.joins(join_expression).select("wiki_page_links.*, metadata.title as title")
    end
  end
end
