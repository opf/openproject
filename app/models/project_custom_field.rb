#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

class ProjectCustomField < CustomField
  # don't pollute the custom_fields table with a section_id column which is only used by ProjectCustomFields
  # use a separate mapping table instead
  has_many :project_custom_field_section_mappings,
           dependent: :destroy,
           inverse_of: :project_custom_field,
           class_name: 'ProjectCustomFieldSectionMapping',
           foreign_key: 'custom_field_id'

  has_many :project_custom_field_sections,
           through: :project_custom_field_section_mappings

  validate :exactly_one_section_mapped

  def type_name
    :label_project_plural
  end

  def self.visible(user = User.current)
    if user.admin?
      all
    else
      where(visible: true)
    end
  end

  def exactly_one_section_mapped
    unless project_custom_field_sections.count == 1
      errors.add(:base, "Exactly one section must be mapped to this custom field.")
    end
  end

  def project_custom_field_section_mapping
    project_custom_field_section_mappings.first
  end

  def project_custom_field_section
    project_custom_field_sections.first
  end

  def project_custom_field_section=(section)
    # without this reload, a nil assignment is not recovered properly
    project_custom_field_sections.reload

    ActiveRecord::Base.transaction do
      project_custom_field_sections.clear
      project_custom_field_sections << section
    end
  end
end
