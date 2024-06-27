#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  belongs_to :project_custom_field_section, class_name: "ProjectCustomFieldSection", foreign_key: :custom_field_section_id,
                                            inverse_of: :custom_fields
  has_many :project_custom_field_project_mappings, class_name: "ProjectCustomFieldProjectMapping", foreign_key: :custom_field_id,
                                                   dependent: :destroy, inverse_of: :project_custom_field

  acts_as_list column: :position_in_custom_field_section, scope: [:custom_field_section_id]

  after_save :activate_required_field_in_all_projects

  validates :custom_field_section_id, presence: true

  def type_name
    :label_project_plural
  end

  def self.visible(user = User.current)
    if user.admin?
      all
    elsif user.allowed_in_any_project?(:select_project_custom_fields)
      where(visible: true)
    else
      allowed_project_ids = Project.allowed_to(user, :view_project_attributes).select(:id).arel

      mapping_table = ProjectCustomFieldProjectMapping.arel_table
      mapping_query = mapping_table.project(Arel.star)
        .where(
          mapping_table[:custom_field_id].eq(arel_table[:id])
          .and(mapping_table[:project_id].in(allowed_project_ids))
        )

      where(visible: true).where(mapping_query.exists)
    end
  end

  def activate_required_field_in_all_projects
    return unless required?

    already_activated_in_project_ids = ProjectCustomFieldProjectMapping.where(custom_field_id: id).pluck(:project_id)

    mappings = Project.where.not(id: already_activated_in_project_ids).map do |project|
      { project_id: project.id, custom_field_id: id }
    end
    ProjectCustomFieldProjectMapping.create!(mappings)
  end
end
