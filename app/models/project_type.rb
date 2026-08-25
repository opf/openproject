# frozen_string_literal: true

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

class ProjectType < ApplicationRecord
  belongs_to :project
  belongs_to :type
  belongs_to :variant, class_name: "TypeVariant", inverse_of: :project_types

  before_validation :default_to_base_variant

  validates :type_id, uniqueness: { scope: :project_id }
  validates :type, presence: true
  validates :variant, presence: true
  validate :variant_belongs_to_type
  validate :variant_is_available_to_project

  private

  def default_to_base_variant
    self.variant ||= type&.default_variant
  end

  def variant_belongs_to_type
    return if variant.nil? || type.nil?
    return if variant.type == type

    errors.add(:variant, :must_belong_to_the_type)
  end

  # Not merely hidden from this project: not activatable here even by an instance administrator.
  def variant_is_available_to_project
    return if variant.nil? || !variant.project_owned?
    return if variant.project_id == project_id

    errors.add(:variant, :must_be_owned_by_the_project)
  end
end
