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

class CostType < ApplicationRecord
  has_many :material_budget_items
  has_many :cost_entries, dependent: :destroy
  has_many :rates, class_name: 'CostRate', foreign_key: 'cost_type_id', dependent: :destroy

  validates_presence_of :name, :unit, :unit_plural
  validates_uniqueness_of :name

  after_update :save_rates

  include ActiveModel::ForbiddenAttributesProtection

  scope :active, -> { where(deleted_at: nil) }

  # finds the default CostType
  def self.default
    CostType.find_by(default: true) || CostType.first
  end

  def is_default?
    default
  end

  def <=>(cost_type)
    name.downcase <=> cost_type.name.downcase
  end

  def current_rate
    rate_at(Date.today)
  end

  def rate_at(date)
    CostRate.where(['cost_type_id = ? and valid_from <= ?', id, date])
            .order(Arel.sql('valid_from DESC'))
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
end
