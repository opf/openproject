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
  class PageLinkComponent
    class AddToRelatedAction
      def initialize(page_info:, linkable:, url_helpers:, already_related:)
        @page_info = page_info
        @linkable = linkable
        @url_helpers = url_helpers
        @already_related = already_related
      end

      def icon = :plus

      def menu_item_args
        return { label:, disabled: true } if already_related

        {
          label:,
          tag: :a,
          href: create_relation_page_link_href,
          content_arguments: { data: { turbo_method: :post } }
        }
      end

      private

      attr_reader :page_info, :linkable, :url_helpers, :already_related

      def label
        I18n.t("wikis.page_link_component.add_to_related_pages")
      end

      def create_relation_page_link_href
        url_helpers.relation_wiki_page_links_path(
          wikis_relation_page_link: {
            provider_id: page_info.provider.id,
            linkable_type: linkable.class.name,
            linkable_id: linkable.id
          },
          identifier: page_info.identifier
        )
      end
    end
  end
end
