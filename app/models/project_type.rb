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
  belongs_to :variant, class_name: "Type", optional: true

  validates :type_id, uniqueness: { scope: :project_id }
  validate :type_is_a_root
  validate :variant_belongs_to_type

  # Callers (especially in test cases) enable a family member without caring whether it is a root or a variant.
  def type=(new_type)
    if new_type&.variant?
      self.variant = new_type
      super(new_type.root)
    else
      super
    end
  end

  def effective_type
    variant || type
  end

  private

  def type_is_a_root
    return if type.nil? || !type.variant?

    errors.add(:type, :must_be_a_root_type)
  end

  def variant_belongs_to_type
    return if variant.nil? || variant.parent_id == type_id

    errors.add(:variant, :must_belong_to_the_type)
  end
end
