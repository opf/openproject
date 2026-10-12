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
  # The "+ Add to-do" row of a group. It asks for the group to be shown with a to-do input row.
  class AddTodoComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(group:, view:)
      super()
      @group = group
      @view = view
    end

    private

    attr_reader :group, :view

    # Rows of the sortable views start with a drag handle, which the link leaves room for.
    def handle_space? = view.in?(%i[today upcoming])

    def link_arguments
      {
        href: Planner::Menu.path_for(view, adding: group),
        scheme: :secondary,
        font_size: :small,
        display: :flex,
        align_items: :center,
        style: "min-height: var(--control-small-size)",
        data: { turbo_stream: true },
        test_selector: "planner-add-todo-#{group}"
      }
    end
  end
end
