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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackages::Details::TabComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable
  include Redmine::MenuManager::MenuHelper

  attr_reader :tab, :work_package, :base_route

  def initialize(work_package:, base_route:, tab: :overview)
    super

    @work_package = work_package
    @tab = tab.to_sym
    @base_route = base_route
  end

  delegate :project, to: :work_package

  def menu = :work_package_split_view

  def menu_items
    @menu_items ||=
      Redmine::MenuManager
        .items(menu, nil)
        .root
        .children
        .select do |node|
          allowed_node?(node, User.current, project) && visible_node?(menu, node)
        end
  end

  def full_screen_tab
    if @tab.name == "overview"
      return :activity
    end

    @tab.name
  end
end
