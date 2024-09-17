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

class CostEntry < ApplicationRecord
  belongs_to :project
  belongs_to :work_package
  belongs_to :user
  belongs_to :logged_by, class_name: "User"
  include ::Costs::DeletedUserFallback
  belongs_to :cost_type
  belongs_to :budget
  belongs_to :rate, class_name: "CostRate"

  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :work_package_id, :project_id, :user_id, :logged_by_id, :cost_type_id, :units, :spent_on
  validates_numericality_of :units, allow_nil: false, message: :invalid
  validates_length_of :comments, maximum: 255, allow_nil: true

  before_save :before_save
  before_validation :before_validation
  after_initialize :after_initialize
  validate :validate

  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  extend CostEntryScopes
  include Entry::Costs
  include Entry::SplashedDates

  def after_initialize
    return unless new_record?

    # This belongs in a SetAttributesService, but cost_entries are not yet created as such
    self.logged_by = User.current

    if cost_type.nil? && default_cost_type = CostType.default
      self.cost_type_id = default_cost_type.id
    end
  end

  def before_validation
    self.project = work_package.project if work_package && project.nil?
  end

  def validate
    errors.add :units, :invalid if units&.negative?
    errors.add :project_id, :invalid if project.nil?
    errors.add :work_package_id, :invalid if work_package.nil? || (project != work_package.project)
    errors.add :cost_type_id, :invalid if cost_type.present? && cost_type.deleted_at.present?
    errors.add :user_id, :invalid if project.present? && !project.users.include?(user) && user_id_changed?

    begin
      spent_on.to_date
    rescue StandardError
      errors.add :spent_on, :invalid
    end
  end

  def before_save
    self.spent_on &&= spent_on.to_date
    update_costs
  end

  def overwritten_costs=(costs)
    write_attribute(:overwritten_costs, CostRate.parse_number_string_to_number(costs))
  end

  def units=(units)
    write_attribute(:units, CostRate.parse_number_string(units))
  end

  def current_rate
    cost_type.rate_at(self.spent_on)
  end

  # Returns true if the cost entry can be edited by usr, otherwise false
  def editable_by?(usr)
    usr.allowed_in_project?(:edit_cost_entries, project) ||
      (usr.allowed_in_project?(:edit_own_cost_entries, project) && user_id == usr.id)
  end

  def creatable_by?(usr)
    usr.allowed_in_project?(:log_costs, project) ||
      (usr.allowed_in_project?(:log_own_costs, project) && user_id == usr.id)
  end

  def costs_visible_by?(usr)
    usr.allowed_in_project?(:view_cost_rates, project) ||
      (usr.id == user_id && !overridden_costs.nil?)
  end

  private

  def cost_attribute
    units
  end
end
