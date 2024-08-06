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

module Projects::WorkPackageCustomFields
  extend ActiveSupport::Concern

  included do
    # Custom field for the project's work_packages
    has_and_belongs_to_many :work_package_custom_fields, # rubocop:disable Rails/HasAndBelongsToMany
                            -> { order("#{CustomField.table_name}.position") },
                            join_table: :custom_fields_projects,
                            association_foreign_key: "custom_field_id"

    # Returns an AR scope of all custom fields enabled for project's work packages
    # (explicitly associated custom fields and custom fields enabled for all projects)
    def all_work_package_custom_fields
      WorkPackageCustomField
        .for_all
        .or(WorkPackageCustomField.where(id: work_package_custom_fields))
    end
  end
end
