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

class Type < ApplicationRecord
  include ::Scopes::Scoped

  before_validation :ensure_base_variant, on: :create
  before_destroy :check_integrity

  belongs_to :color, optional: true, class_name: "Color"

  has_many :work_packages, dependent: nil

  # Every type has a base variant plus any number of named ones.
  has_many :variants, class_name: "TypeVariant", dependent: :destroy, autosave: true, inverse_of: :type

  # Projects using this type. Which variant each of them applies is on the join row.
  has_many :project_types, dependent: :delete_all
  has_many :projects, through: :project_types

  acts_as_list

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 255 }
  validates :builtin_identifier, uniqueness: true, allow_nil: true

  scopes :milestone

  default_scope { order(:position) }

  scope :visible, ->(user = User.current) {
    if user.allowed_in_any_project?(:view_work_packages) || user.allowed_in_any_project?(:manage_types)
      all
    else
      none
    end
  }

  delegate :to_s, to: :name

  # Read from the collection rather than through an association of its own, so a base variant
  # that #ensure_base_variant has only built is visible before it is saved. Preload `:variants`
  # to ask this of many types at once.
  def default_variant
    variants.detect(&:is_default_variant?)
  end

  def <=>(other)
    name <=> other.name
  end

  def builtin?
    builtin_identifier.present?
  end

  # The types the given project(s) use.
  #
  # Resolved as a subquery rather than a join so a type used by several projects yields one
  # row: a join would duplicate it, which the eager load only hid from callers reading records
  # and not from those plucking ids.
  def self.enabled_in(project)
    where(id: ProjectType.where(project_id: project).select(:type_id))
  end

  private

  def ensure_base_variant
    return if variants.any?(&:is_default_variant?)

    variants.build(is_default_variant: true, variant_name: nil)
  end

  def check_integrity # rubocop:disable Naming/PredicateMethod
    if builtin?
      errors.add(:base, I18n.t("types.errors.builtin_cannot_be_deleted"))
      throw :abort
    end

    throw :abort if WorkPackage.exists?(type_id: id)

    true
  end
end
