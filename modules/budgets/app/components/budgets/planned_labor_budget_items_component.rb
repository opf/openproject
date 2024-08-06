# frozen_string_literal: true

# -- copyright
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
# ++

class Budgets::PlannedLaborBudgetItemsComponent < ApplicationComponent
  options :budget, :project

  def item_hours(item)
    helpers.l_hours(item.hours)
  end

  def item_user(item)
    helpers.avatar(item.principal, hide_name: false, size: :mini)
  end

  def item_comments(item)
    item.comments
  end

  def item_costs(item)
    item.costs_visible_by?(User.current) ? number_to_currency(item.costs) : ""
  end

  def planned_sum
    number_to_currency(budget.labor_budget)
  end

  def view_rates_allowed?
    User.current.allowed_in_project?(:view_hourly_rates,
                                     project) ||
      User.current.allowed_in_project?(:view_own_hourly_rate,
                                       project)
  end
end
