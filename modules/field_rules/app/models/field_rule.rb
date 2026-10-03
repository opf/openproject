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
# frozen_string_literal: true

class FieldRule < ApplicationRecord
  self.table_name = "field_rules"

  belongs_to :rule_set, class_name: "FieldRuleSet", inverse_of: :rules

  validates :field_key, presence: true, length: { maximum: 100 }
  validates :default_value, length: { maximum: 5000 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 100_000 }
  validate :field_is_configurable
  validate :state_combination_is_valid
  validate :default_matches_field

  before_validation :normalize_state
  before_validation { @configurable = nil }
  after_save { ::FieldRules::Resolver.reset_cache }
  after_destroy { ::FieldRules::Resolver.reset_cache }

  def default_present? = default_value.present?

  private

  def normalize_state
    self.read_only = false if hidden
    self.default_value = nil if default_value.blank?
  end

  def field_is_configurable
    errors.add(:field_key, :unknown_field) unless configurable_field?
  end

  def configurable_field?
    return @configurable unless @configurable.nil?

    @configurable = ::FieldRules::Fields.configurable?(field_key)
  end

  def state_combination_is_valid
    errors.add(:required, :hidden_and_required) if hidden && required
    errors.add(:required, :read_only_required_without_default) if required && read_only && !default_present?
  end

  def default_matches_field
    return if default_value.blank? || !configurable_field?

    error = ::FieldRules::Fields.default_error(field_key, default_value)
    errors.add(:default_value, error) if error
  end
end
