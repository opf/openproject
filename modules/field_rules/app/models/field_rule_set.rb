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

class FieldRuleSet < ApplicationRecord
  self.table_name = "field_rule_sets"
  MAX_RULES = 100

  has_many :rules, -> { order(:position, :id) }, class_name: "FieldRule", foreign_key: :rule_set_id,
                                                  inverse_of: :rule_set, dependent: :destroy, autosave: true
  has_many :scheme_items, class_name: "FieldRuleSchemeItem", foreign_key: :rule_set_id, inverse_of: :rule_set

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validate :rules_unique_and_bounded

  before_destroy :prevent_destroy
  after_save { ::FieldRules::Resolver.reset_cache }
  after_destroy { ::FieldRules::Resolver.reset_cache }

  scope :active, -> { where(active: true) }

  def rule_for(field_key) = rules.find { |rule| rule.field_key == field_key.to_s }

  private

  def prevent_destroy
    errors.add(:base, :cannot_be_deleted)
    throw :abort
  end

  def rules_unique_and_bounded
    live = rules.reject(&:marked_for_destruction?)
    errors.add(:rules, :duplicate_fields) if live.map(&:field_key).uniq.size != live.size
    errors.add(:rules, :too_many, count: MAX_RULES) if live.size > MAX_RULES
  end
end
