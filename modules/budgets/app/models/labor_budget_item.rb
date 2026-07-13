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

class LaborBudgetItem < ApplicationRecord
  belongs_to :budget
  belongs_to :user
  belongs_to :principal, foreign_key: "user_id"

  include ::Costs::DeletedUserFallback

  validates :comments, length: { maximum: 255, allow_nil: true }
  validates :user, presence: true
  validates :budget, presence: true
  validates :hours, numericality: { allow_nil: false }
  validate :user_is_member_of_budget_project

  include ActiveModel::ForbiddenAttributesProtection
  # user_id correctness is ensured in Budget#*_labor_budget_item_attributes=

  include Scopes::Scoped

  scopes :visible

  scope :visible_costs, lambda { |*args|
    visible(args.first || User.current)
  }

  def costs
    amount || calculated_costs
  end

  def overridden_costs?
    amount.present?
  end

  def calculated_costs(fixed_date = budget.fixed_date, project_id = budget.project_id)
    if user_id && hours && (rate = HourlyRate.at_date_for_user_in_project(fixed_date, user_id, project_id))
      rate.rate * hours
    else
      0.0
    end
  end

  def costs_visible_by?(usr)
    usr.allowed_in_project?(:view_hourly_rates, budget.project) ||
      (usr.id == user_id && usr.allowed_in_project?(:view_own_hourly_rate, budget.project))
  end

  private

  def user_is_member_of_budget_project
    return if principal.nil? || budget&.project.nil?

    unless Principal.possible_assignee(budget.project).exists?(id: principal.id)
      errors.add(:principal, :not_a_member_of_budget_project)
    end
  end
end
