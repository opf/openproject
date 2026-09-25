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

class FormConfigurationAttribute < ApplicationRecord
  CUSTOM_FIELD_PREFIX = TypeVariant::ConfigurationLinkable::CUSTOM_FIELD_ELEMENT_PREFIX

  belongs_to :type_variant, inverse_of: :form_attributes
  belongs_to :group,
             class_name: "FormConfigurationGroup",
             foreign_key: :form_configuration_group_id,
             optional: true,
             inverse_of: :members
  belongs_to :custom_field, class_name: "WorkPackageCustomField", optional: true

  # add_new_at: nil keeps acts_as_list from positioning inactive records on create.
  acts_as_list scope: :form_configuration_group, add_new_at: nil
  include Lists::MoveAfterAnchor

  scope :active, -> { where.not(form_configuration_group_id: nil) }
  scope :inactive, -> { where(form_configuration_group_id: nil) }

  validates :attribute_key, presence: true, if: -> { custom_field_id.nil? }
  validates :attribute_key, absence: true, unless: -> { custom_field_id.nil? }
  validate :placement_is_complete
  validate :group_is_an_attribute_group_of_the_owner

  def self.reference_for(key)
    key = key.to_s
    if (custom_field_id = key[/\Acustom_field_(\d+)\z/, 1])
      { custom_field_id: custom_field_id.to_i, attribute_key: nil }
    else
      { custom_field_id: nil, attribute_key: key }
    end
  end

  def key
    custom_field_id ? "#{CUSTOM_FIELD_PREFIX}#{custom_field_id}" : attribute_key
  end

  def active? = form_configuration_group_id.present?

  # Both transitions reload under a row lock first: acts_as_list compacts the list the record
  # leaves from the position held in memory, which is stale as soon as a neighbour moved.
  def place!(group:, position:)
    with_lock do
      if form_configuration_group_id == group.id
        insert_at(position)
      else
        update!(group:, position:)
      end
    end
  end

  def deactivate!
    with_lock { update!(group: nil, position: nil) if active? }
  end

  private

  def placement_is_complete
    return if group.nil? == position.nil?

    errors.add(group.nil? ? :group : :position, :blank)
  end

  def group_is_an_attribute_group_of_the_owner
    return if group.nil?

    errors.add(:group, :invalid) if group.type_variant_id != type_variant_id || !group.attribute?
  end
end
