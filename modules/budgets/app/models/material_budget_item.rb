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

class MaterialBudgetItem < ApplicationRecord
  belongs_to :budget
  belongs_to :cost_type

  validates_length_of :comments, maximum: 255, allow_nil: true
  validates_presence_of :cost_type

  include ActiveModel::ForbiddenAttributesProtection

  def self.visible(user)
    includes(budget: :project)
      .references(:projects)
      .merge(Project.allowed_to(user, :view_cost_rates))
  end

  scope :visible_costs, lambda { |*args|
    scope = visible(args.first || User.current)

    if args[1]
      scope = scope.where(budget: { projects_id: args[1].id })
    end

    scope
  }

  def costs
    amount || calculated_costs
  end

  def overridden_costs?
    amount.present?
  end

  def calculated_costs(fixed_date = budget.fixed_date)
    if units && cost_type && rate = cost_type.rate_at(fixed_date)
      rate.rate * units
    else
      0.0
    end
  end

  def costs_visible_by?(usr)
    usr.allowed_in_project?(:view_cost_rates, budget.project)
  end
end
