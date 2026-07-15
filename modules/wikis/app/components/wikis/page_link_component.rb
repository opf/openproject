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

    attr_reader :source

    def initialize(model = nil, menu_actions: [], source: nil, **)
      @menu_actions = menu_actions
      @source = source

      super(model, **)
    end

    def badge_label
      I18n.t("wikis.page_links.source.parent") if source == :parent
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
      menu_actions.any?
    end

    def menu_items(menu)
      menu_actions.each do |action|
        menu.with_item(**action.menu_item_args) do |item|
          item.with_leading_visual_icon(icon: action.icon)
        end
      end
    end

    private

    attr_reader :menu_actions
  end
end
