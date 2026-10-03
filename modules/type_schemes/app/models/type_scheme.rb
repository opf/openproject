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

class TypeScheme < ApplicationRecord
  self.table_name = "type_schemes"

  has_many :items, -> { order(:position) }, class_name: "TypeSchemeItem",
           foreign_key: :scheme_id, inverse_of: :scheme, dependent: :destroy
  has_many :project_assignments, class_name: "ProjectTypeScheme", foreign_key: :scheme_id,
           inverse_of: :scheme, dependent: :restrict_with_error
  has_many :projects, through: :project_assignments

  validates :name, presence: true, uniqueness: true
  validates :is_default, uniqueness: true, if: :is_default
  validate :types_unique
  validate :exactly_one_default_item, if: :active

  scope :active, -> { where(active: true) }

  def types = items.sort_by(&:position).map(&:type)
  def default_item = items.find(&:is_default)
  def default_type = default_item&.type

  private

  def types_unique
    ids = items.reject(&:marked_for_destruction?).map(&:type_id)
    errors.add(:items, :duplicate_types) if ids.uniq.size != ids.size
  end

  def exactly_one_default_item
    live = items.reject(&:marked_for_destruction?)
    errors.add(:items, :exactly_one_default) unless live.count(&:is_default) == 1
  end
end
