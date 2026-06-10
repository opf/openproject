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

class CostType < ApplicationRecord
  has_many :material_budget_items
  has_many :cost_entries, dependent: :destroy
  has_many :rates, class_name: "CostRate", dependent: :destroy
  has_many :cost_types_projects, dependent: :destroy
  has_many :projects, through: :cost_types_projects

  validates :unit, :unit_plural, presence: true
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  after_update :save_rates
  after_save :persist_current_rate_input

  include ActiveModel::ForbiddenAttributesProtection

  scope :active, -> { where(deleted_at: nil) }
  scope :for_all, -> { where(for_all_projects: true) }
  scope :available_for_project, ->(project) {
    project_id = project.is_a?(Project) ? project.id : project
    where(for_all_projects: true)
      .or(where(id: CostTypesProject.where(project_id:).select(:cost_type_id)))
  }

  # finds the default CostType
  def self.default
    CostType.find_by(default: true) || CostType.first
  end

  # Returns the default cost type for the given project, falling back to the first
  # cost type available in that project when the global default is not available there.
  def self.default_for_project(project)
    available = available_for_project(project).active
    available.find_by(default: true) || available.first
  end

  def is_default?
    default
  end

  def <=>(other)
    name.downcase <=> other.name.downcase
  end

  attr_writer :current_rate

  def current_rate
    return @current_rate if instance_variable_defined?(:@current_rate)

    rate_at(Date.current)&.rate
  end

  def rate_at(date)
    CostRate.where(["cost_type_id = ? and valid_from <= ?", id, date])
            .order(Arel.sql("valid_from DESC"))
            .first
  end

  def visible?(user)
    user.admin?
  end

  def to_s
    name
  end

  def new_rate_attributes=(rate_attributes)
    rate_attributes.each do |_index, attributes|
      attributes[:rate] = Rate.parse_number_string(attributes[:rate])
      rates.build(attributes)
    end
  end

  def existing_rate_attributes=(rate_attributes)
    rates.reject(&:new_record?).each do |rate|
      attributes = rate_attributes[rate.id.to_s]

      has_rate = false
      if attributes && attributes[:rate].present?
        attributes[:rate] = Rate.parse_number_string(attributes[:rate])
        has_rate = true
      end

      if has_rate
        rate.attributes = attributes
      else
        rates.delete(rate)
      end
    end
  end

  def save_rates
    rates.each(&:save!)
  end

  def persist_current_rate_input
    return unless instance_variable_defined?(:@current_rate)

    amount = parse_current_rate_amount(remove_instance_variable(:@current_rate))
    return if amount.nil?

    today = Time.zone.today
    if (rate = rate_at(today))
      rate.update!(rate: amount)
    else
      rates.create!(valid_from: today, rate: amount)
    end
  end

  def parse_current_rate_amount(value)
    return if value.to_s.strip.empty?

    CostRate.parse_number_string_to_number(value.to_s)
  end
end
