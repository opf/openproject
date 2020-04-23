#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class CostEntry < ApplicationRecord
  belongs_to :project
  belongs_to :work_package
  belongs_to :user
  include ::OpenProject::Costs::DeletedUserFallback
  belongs_to :cost_type
  belongs_to :cost_object
  belongs_to :rate, class_name: 'CostRate'

  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :work_package_id, :project_id, :user_id, :cost_type_id, :units, :spent_on
  validates_numericality_of :units, allow_nil: false, message: :invalid
  validates_length_of :comments, maximum: 255, allow_nil: true

  before_save :before_save
  before_validation :before_validation
  after_initialize :after_initialize
  validate :validate

  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  extend CostEntryScopes

  def after_initialize
    if new_record? && cost_type.nil?
      if default_cost_type = CostType.default
        self.cost_type_id = default_cost_type.id
      end
    end
  end

  def before_validation
    self.project = work_package.project if work_package && project.nil?
  end

  def validate
    errors.add :units, :invalid if units && (units < 0)
    errors.add :project_id, :invalid if project.nil?
    errors.add :work_package_id, :invalid if work_package.nil? || (project != work_package.project)
    errors.add :cost_type_id, :invalid if cost_type.present? && cost_type.deleted_at.present?
    errors.add :user_id, :invalid if project.present? && !project.users.include?(user) && user_id_changed?

    begin
      spent_on.to_date
    rescue Exception
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

  # tyear, tmonth, tweek assigned where setting spent_on attributes
  # these attributes make time aggregations easier
  def spent_on=(date)
    super
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
  end

  def real_costs
    # This methods returns the actual assigned costs of the entry
    overridden_costs || costs || calculated_costs
  end

  def calculated_costs(rate_attr = nil)
    rate_attr ||= current_rate
    units * rate_attr.rate
  rescue
    0.0
  end

  def update_costs(rate_attr = nil)
    rate_attr ||= current_rate
    if rate_attr.nil?
      self.costs = 0.0
      self.rate = nil
      return
    end

    self.costs = calculated_costs(rate_attr)
    self.rate = rate_attr
  end

  def update_costs!(rate_attr = nil)
    update_costs(rate_attr)
    self.save!
  end

  def current_rate
    cost_type.rate_at(self.spent_on)
  end

  # Returns true if the cost entry can be edited by usr, otherwise false
  def editable_by?(usr)
    usr.allowed_to?(:edit_cost_entries, project) ||
      (usr.allowed_to?(:edit_own_cost_entries, project) && user_id == usr.id)
  end

  def creatable_by?(usr)
    usr.allowed_to?(:log_costs, project) ||
      (usr.allowed_to?(:log_own_costs, project) && user_id == usr.id)
  end

  def costs_visible_by?(usr)
    usr.allowed_to?(:view_cost_rates, project) ||
      (usr.id == user_id && !overridden_costs.nil?)
  end
end
