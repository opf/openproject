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

class FormConfiguration < ApplicationRecord
  include ::Type::AttributeGroups

  has_many :type_variants, dependent: :restrict_with_error, inverse_of: :form_configuration

  has_many :form_attributes, class_name: "FormConfigurationAttribute", inverse_of: :form_configuration,
                             dependent: :delete_all
  has_many :form_groups, -> { order(:position) }, class_name: "FormConfigurationGroup",
                                                  inverse_of: :form_configuration,
                                                  dependent: :destroy

  has_many :custom_field_memberships, -> { active.where.not(custom_field_id: nil) },
           class_name: "FormConfigurationAttribute",
           inverse_of: :form_configuration,
           dependent: nil
  has_many :custom_fields, through: :custom_field_memberships

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 255 }

  after_save :persist_staged_attribute_groups

  delegate :default_attribute_groups, :work_package_attributes, to: :neutral_variant

  def self.implicit_name(source)
    base = source.to_s.strip.presence
    available_name(base && I18n.t("forms.name.implicit", name: base))
  end

  def self.available_name(base)
    base = base.to_s.strip.presence || I18n.t("forms.name.fallback")
    return base unless exists?(["LOWER(name) = LOWER(?)", base])

    suffix = 2
    suffix += 1 while exists?(["LOWER(name) = LOWER(?)", "#{base} (#{suffix})"])
    "#{base} (#{suffix})"
  end

  def stored_attribute_groups
    return if new_record?
    return @stored_attribute_groups if defined?(@stored_attribute_groups)

    @stored_attribute_groups = (attribute_group_rows.tuples if form_groups.any? || form_attributes.exists?)
  end

  def stage_attribute_groups(groups)
    @staged_attribute_groups = groups unless persisted? && attribute_group_rows.matches?(groups)
  end

  def custom_field_ids=(ids)
    self.attribute_groups = CustomFieldPlacement.new(form_attribute_groups, Array(ids).compact_blank.map(&:to_i)).groups
    save! if persisted?
  end

  def custom_fields=(fields)
    self.custom_field_ids = fields.map(&:id)
  end

  def attribute_groups_will_change! = @attribute_groups_changed = true

  def attribute_groups_changed? = @attribute_groups_changed.present?

  def attribute_groups_was = new_record? ? [] : attribute_group_rows.tuples

  def changed_for_autosave? = super || @staged_attribute_groups.present?

  def reload(*)
    @staged_attribute_groups = nil
    @attribute_groups_changed = nil
    remove_instance_variable(:@stored_attribute_groups) if defined?(@stored_attribute_groups)
    super
  end

  private

  def attribute_group_rows = AttributeGroupRows.new(self)

  def persist_staged_attribute_groups
    groups = @staged_attribute_groups
    @staged_attribute_groups = nil
    @attribute_groups_changed = nil

    return unless groups

    attribute_group_rows.store(groups)
    remove_instance_variable(:@stored_attribute_groups) if defined?(@stored_attribute_groups)
  end

  def neutral_variant
    @neutral_variant ||= TypeVariant.new(type: Type.new).tap do |variant|
      variant.association(:form_configuration).target = self
    end
  end
end
