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
  class PageLinkComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    alias_method :page_info_result, :model

    attr_reader :actions

    def initialize(model = nil, actions: [], page_link: nil, **)
      @actions = actions
      @page_link = page_link

      super(model, **)
    end

    def page_title
      page_info_result.either(
        ->(pi) { pi.title },
        ->(error) do
          case error
          in { code: :not_found }
            I18n.t("wikis.page_links.errors.page_not_found")
          in { code: :forbidden }
            I18n.t("wikis.page_links.errors.page_access_forbidden")
          else
            I18n.t("wikis.page_links.errors.unexpected")
          end
        end
      )
    end

    def page_href
      page_info_result.value!.href
    end

    def error?
      page_info_result.failure?
    end

    def show_action_menu?
      actions.any?
    end

    def menu_items(menu)
      if actions.include?(:remove)
        deletion_action_item(menu)
      end
    end

    private

    def project
      @page_link&.linkable&.project
    end

    def deletion_action_item(menu)
      return if @page_link.nil?
      return unless user_allowed_to_delete?

      href = url_helpers.confirm_delete_dialog_relation_wiki_page_link_path(@page_link)

      menu.with_item(label: t(".remove"),
                     scheme: :danger,
                     tag: :a,
                     href:,
                     content_arguments: { data: { controller: "async-dialog" } }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def user_allowed_to_delete?
      helpers.current_user.allowed_in_project?(:manage_wiki_page_links, project)
    end
  end
end
