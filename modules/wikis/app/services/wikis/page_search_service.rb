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
  class PageSearchService
    include Dry::Monads[:result]

    attr_reader :provider, :user

    def initialize(provider:, user:)
      @provider = provider
      @user = user
    end

    def search_pages(query)
      return Success([]) if query.blank?

      if url?(query)
        search_by_url(query)
      else
        search_by_query(query)
      end
    end

    private

    def url?(string)
      uri = URI.parse(string)

      %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      false
    end

    def search_by_url(query)
      Adapters::Input::PageInfoForUrl.build(url: query).bind do |input_data|
        provider.auth_strategy_for(user).bind do |auth_strategy|
          provider.resolve("queries.page_info_for_url").call(input_data:, auth_strategy:).fmap { [it] }
        end
      end
    end

    def search_by_query(query)
      Adapters::Input::SearchPages.build(query:).bind do |input_data|
        provider.auth_strategy_for(user).bind do |auth_strategy|
          provider.resolve("queries.search_pages").call(input_data:, auth_strategy:)
        end
      end
    end
  end
end
