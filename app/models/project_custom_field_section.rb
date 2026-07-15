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

class ProjectCustomFieldSection < CustomFieldSection
  has_many :custom_fields,
           class_name: "ProjectCustomField",
           dependent: :destroy,
           foreign_key: :custom_field_section_id,
           inverse_of: :project_custom_field_section

  # Returns [[section, [ordered_cfs]], ...] for the given project's available,
  # visible custom fields. Sections are ordered by position, fields within each
  # section by attribute_order. Two SQL queries: one for the CFs, one for the sections.
  def self.with_available_fields_for(project)
    grouped_in_order(project.available_custom_fields)
  end

  # Groups the given custom fields by their section, with sections ordered by
  # position and the fields within each section ordered by attribute_order.
  # Sections that end up with no ordered field are dropped.
  # Returns [[section, [ordered_cfs]], ...]. Two SQL queries: the given relation
  # is materialised once, then the relevant sections are loaded.
  def self.grouped_in_order(custom_fields)
    cfs_by_section_id = custom_fields.group_by(&:custom_field_section_id)

    where(id: cfs_by_section_id.keys)
      .order(:position)
      .filter_map do |section|
        cf_by_key = cfs_by_section_id[section.id].index_by(&:column_name)
        ordered = section.attribute_order.filter_map { |key| cf_by_key[key] }
        [section, ordered] if ordered.any?
      end
  end
end
