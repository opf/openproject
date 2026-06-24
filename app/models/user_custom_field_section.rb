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

class UserCustomFieldSection < CustomFieldSection
  BUILT_IN_ATTRIBUTES = %w[login firstname lastname mail language].freeze

  has_many :custom_fields,
           class_name: "UserCustomField",
           dependent: :restrict_with_exception,
           foreign_key: :custom_field_section_id,
           inverse_of: :user_custom_field_section

  # Returns sections that contain at least one of the given custom field IDs,
  # ordered by section position.  Field ordering within each section is driven
  # by attribute_order in Ruby.
  scope :with_custom_fields, ->(ids) {
    joins(:custom_fields)
      .where(custom_fields: { id: ids })
      .includes(:custom_fields)
      .order("custom_field_sections.position")
  }

  # Returns [[section, [ordered_cfs]], ...] for the given user's filled, visible
  # custom fields.  Pass visible_on_user_card: true to restrict to hover-card fields.
  # Two SQL queries: one for sections, one for the relevant CFs (both use filled_cf_ids
  # as a subquery so no values are materialised into Ruby memory).
  def self.with_filled_fields_for(user, visible_on_user_card: nil) # rubocop:disable Metrics/AbcSize
    cf_scope = UserCustomField.visible(User.current)
    cf_scope = cf_scope.where(visible_on_user_card: true) if visible_on_user_card

    filled_cf_ids = user.custom_values
                        .where(custom_field: cf_scope)
                        .where.not(value: [nil, ""])
                        .select(:custom_field_id)

    sections = joins(:custom_fields)
                 .where(custom_fields: { id: filled_cf_ids })
                 .distinct
                 .order(:position)

    cfs_by_section = cf_scope.where(id: filled_cf_ids)
                              .group_by(&:custom_field_section_id)

    sections.filter_map do |section|
      cf_by_key = (cfs_by_section[section.id] || []).index_by(&:column_name)
      ordered = section.attribute_order.filter_map { |key| cf_by_key[key] }
      [section, ordered] if ordered.any?
    end
  end

  def untitled?
    name.blank?
  end
end
