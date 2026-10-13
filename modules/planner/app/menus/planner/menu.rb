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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Planner
  class Menu < Submenu
    ICONS = { today: :sun, upcoming: :calendar, overdue: :alert, completed: :"check-circle" }.freeze

    def initialize(params:, user:, project:)
      super(view_type: nil, params:)
      @user = user
      @project = project
    end

    def menu_items
      [menu_group(header: nil, children: ICONS.map { |view, icon| view_item(view, icon) })]
    end

    def self.path_for(view, **query)
      url_helpers = Rails.application.routes.url_helpers
      view.to_s == "today" ? url_helpers.planner_path(**query) : url_helpers.planner_view_path(view, **query)
    end

    private

    attr_reader :user, :project

    def view_item(view, icon)
      href = self.class.path_for(view)

      OpenProject::Menu::MenuItem.new(title: I18n.t("planner.views.#{view}"),
                                      href:,
                                      icon:,
                                      selected: params[:current_href] == href,
                                      count: (overdue_count if view == :overdue))
    end

    def overdue_count
      Overdue.new(user:, project:).count.nonzero?
    end
  end
end
