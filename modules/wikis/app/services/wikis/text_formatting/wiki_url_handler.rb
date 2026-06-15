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
  module TextFormatting
    class WikiUrlHandler
      include Dry::Monads[:result]

      def match?(uri)
        page_info_for_url(uri).present?
      end

      def html_for(uri)
        page_info = page_info_for_url(uri)
        return nil if page_info.nil?

        # We only render successful macro components, in case of a failure we fallback to leaving the link as it was originally
        # pasted into the document.
        InlinePageLinkMacroComponent.new(Success(page_info)).render_in(view_context)
      end

      private

      def providers
        @providers ||= Provider.visible.enabled.to_a
      end

      def page_info_for_url(uri)
        return nil unless scheme_valid?(uri)
        return cached_page_infos[uri] if cached_page_infos.key?(uri)

        Adapters::Input::PageInfoForUrl.build(url: uri.to_s).bind do |input_data|
          providers.each do |provider|
            provider_page_info_for_url(input_data:, provider:) do |page_info|
              cached_page_infos[uri] = page_info
              return page_info
            end
          end
        end

        cached_page_infos[uri] = nil
        nil
      end

      def provider_page_info_for_url(input_data:, provider:, &)
        provider.auth_strategy_for(user).bind do |auth_strategy|
          provider.resolve("queries.page_info_for_url").call(input_data:, auth_strategy:).bind(&)
        end
      end

      # The expected lifecycle of the handler is the parsing of a single document. Using the cache prevents
      # double requests for calls between #match? and #html_for, as well as when a link appears twice in the same document.
      def cached_page_infos
        @cached_page_infos ||= {}
      end

      def user = User.current

      def scheme_valid?(uri) = %w[http https].include?(uri.scheme)

      def view_context
        @view_context ||= ApplicationController.new.view_context
      end
    end
  end
end
