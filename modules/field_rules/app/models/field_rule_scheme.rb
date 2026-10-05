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

class FieldRuleScheme < ApplicationRecord
  self.table_name = "field_rule_schemes"
  MAX_ITEMS = 200

  has_many :items, class_name: "FieldRuleSchemeItem", foreign_key: :scheme_id,
                   inverse_of: :scheme, dependent: :destroy, autosave: true
  has_many :project_assignments, class_name: "ProjectFieldRuleScheme", foreign_key: :scheme_id,
                                 inverse_of: :scheme
  has_many :projects, through: :project_assignments

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validate :types_unique_and_bounded

  before_destroy :prevent_destroy
  after_save { ::FieldRules::Resolver.reset_cache }
  after_destroy { ::FieldRules::Resolver.reset_cache }

  scope :active, -> { where(active: true) }

  def rule_set_for(type_id) = items.find { |item| item.type_id == type_id }&.rule_set

  private

  def prevent_destroy
    errors.add(:base, :cannot_be_deleted)
    throw :abort
  end

  def types_unique_and_bounded
    live = items.reject(&:marked_for_destruction?)
    errors.add(:items, :duplicate_types) if live.map(&:type_id).uniq.size != live.size
    errors.add(:items, :too_many, count: MAX_ITEMS) if live.size > MAX_ITEMS
  end
end
