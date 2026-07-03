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
    class RemoveAction
      def initialize(page_link:, url_helpers:)
        @page_link = page_link
        @url_helpers = url_helpers
      end

      def icon = :trash

      def menu_item_args
        {
          label: I18n.t("wikis.page_link_component.remove"),
          scheme: :danger,
          tag: :a,
          href: url_helpers.confirm_delete_dialog_relation_wiki_page_link_path(page_link),
          content_arguments: { data: { controller: "async-dialog" } }
        }
      end

      private

      attr_reader :page_link, :url_helpers
    end
  end
end
