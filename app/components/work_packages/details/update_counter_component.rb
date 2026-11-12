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

class WorkPackages::Details::UpdateCounterComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include OpTurbo::Streamable

  attr_reader :work_package, :menu_name

  def initialize(work_package:, menu_name:)
    super

    @work_package = work_package
    @menu = find_menu_item(menu_name)
  end

  def call
    render Primer::Beta::Counter
      .new(count:,
           hide_if_zero: true,
           id: wrapper_key,
           test_selector: "wp-details-tab-component--#{@menu.name}-counter")
  end

  # We don't need a wrapper component, but wrap on the counter id
  def wrapped?
    true
  end

  def wrapper_key
    "wp-details-tab-#{@menu.name}-counter"
  end

  def render?
    @menu.present?
  end

  def count
    @menu
      .badge(work_package:)
      .to_i
  end

  def find_menu_item(menu_name)
    Redmine::MenuManager
        .items(:work_package_split_view, nil)
        .root
        .children
        .detect { |node| node.name.to_s == menu_name }
  end
end
