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

class WorkPackageCustomField < CustomField
  has_and_belongs_to_many :projects,
                          join_table: "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                          foreign_key: "custom_field_id"
  has_and_belongs_to_many :types,
                          join_table: "#{table_name_prefix}custom_fields_types#{table_name_suffix}",
                          foreign_key: "custom_field_id"
  has_many :work_packages,
           through: :custom_values,
           source: :customized,
           source_type: "WorkPackage"

  scopes :visible,
         :on_visible_type_and_project

  scope :usable_as_custom_action, -> {
    where.not(field_format: %w[hierarchy weighted_item_list])
         .order(:name)
  }

  def self.summable
    where(field_format: %w[int float])
  end

  def summable?
    %w[int float].include?(field_format)
  end

  def visible?(usr = User.current, project: nil)
    self.class.visible(usr, project:).exists?(id: id)
  end

  def type_name
    :label_work_package_plural
  end
end
