#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class MaterialBudgetItem < ActiveRecord::Base
  belongs_to :cost_object
  belongs_to :cost_type

  validates_length_of :comments, maximum: 255, allow_nil: true
  validates_presence_of :cost_type

  include ActiveModel::ForbiddenAttributesProtection

  def self.visible(user)
    includes(cost_object: :project)
      .references(:projects)
      .merge(Project.allowed_to(user, :view_cost_rates))
  end

  scope :visible_costs, lambda { |*args|
    scope = visible(args.first || User.current)

    if args[1]
      scope = scope.where(cost_object: { projects_id: args[1].id })
    end

    scope
  }

  def costs
    budget || calculated_costs
  end

  def overridden_budget?
    budget.present?
  end

  def calculated_costs(fixed_date = cost_object.fixed_date)
    if units && cost_type && rate = cost_type.rate_at(fixed_date)
      rate.rate * units
    else
      0.0
    end
  end

  def costs_visible_by?(usr)
    usr.allowed_to?(:view_cost_rates, cost_object.project)
  end
end
