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
  has_one :default_variant, -> { default_variant }, class_name: "TypeVariant", inverse_of: :type, dependent: nil

  # Projects using this type. Which variant each of them applies is on the join row.
  has_many :project_types, dependent: :delete_all
  has_many :projects, through: :project_types

  acts_as_list

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 255 }

  scopes :milestone

  default_scope { order(:position) }

  scope :without_standard, -> { where(is_standard: false).order(:position) }
  scope :default, -> { where(is_default: true) }
  scope :visible, ->(user = User.current) {
    if user.allowed_in_any_project?(:view_work_packages) || user.allowed_in_any_project?(:manage_types)
      all
    else
      none
    end
  }

  delegate :to_s, to: :name

  # has_one with a scope does not automatically see a base variant that was just
  # built or autosaved via #variants. Prefer the in-memory collection in that case
  # so callers like ProjectType and the workspace factory see it without a reload.
  def default_variant
    if association(:variants).loaded? || association(:variants).target.any?
      variants.target.detect(&:is_default_variant?) || association(:default_variant).reader
    else
      association(:default_variant).reader
    end
  end

  # A new named variant starts out Linked to the base variant for every aspect, which is what
  # makes it a variation of that configuration rather than an empty one. Each aspect goes
  # Independent later, when someone edits it.
  def build_variant(attributes = {})
    variants.new(attributes).tap do |variant|
      TypeVariant::ASPECTS.each { |aspect| variant.public_send(:"#{aspect}_source=", default_variant) }
    end
  end

  # Form custom fields live on the base variant. Prefer `default_variant.custom_fields`.
  # Kept temporarily so the many call sites that still write `type.custom_fields << cf` keep
  # working while they are migrated.
  def custom_fields
    OpenProject::Deprecation.replaced("Type#custom_fields", "Type#default_variant.custom_fields", caller_locations)

    default_variant.custom_fields
  end

  def custom_fields=(values)
    OpenProject::Deprecation.replaced("Type#custom_fields=", "Type#default_variant.custom_fields=", caller_locations)

    default_variant.custom_fields = values
  end

  def custom_field_ids
    OpenProject::Deprecation.replaced("Type#custom_field_ids", "Type#default_variant.custom_field_ids", caller_locations)

    default_variant.custom_field_ids
  end

  def custom_field_ids=(values)
    OpenProject::Deprecation.replaced("Type#custom_field_ids=", "Type#default_variant.custom_field_ids=", caller_locations)

    default_variant.custom_field_ids = values
  end

  # Form configuration lives on the base variant. Prefer `default_variant.attribute_groups`.
  def attribute_groups
    OpenProject::Deprecation.replaced("Type#attribute_groups", "Type#default_variant.attribute_groups", caller_locations)

    default_variant.attribute_groups
  end

  def attribute_groups=(values)
    OpenProject::Deprecation.replaced("Type#attribute_groups=", "Type#default_variant.attribute_groups=", caller_locations)

    default_variant.attribute_groups = values
  end

  def reset_attribute_groups
    OpenProject::Deprecation.replaced("Type#reset_attribute_groups",
                                      "Type#default_variant.reset_attribute_groups",
                                      caller_locations)

    default_variant.reset_attribute_groups
  end

  def <=>(other)
    name <=> other.name
  end

  def self.standard_type
    where(is_standard: true).first
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
    throw :abort if is_standard?
    throw :abort if WorkPackage.exists?(type_id: id)

    true
  end
end
