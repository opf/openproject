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

module Projects
  class ArchiveContract < ::BaseContract
    validate :validate_no_foreign_wp_references
    validate :validate_has_archive_project_permission

    protected

    # Check that there is no wp of a non descendant project that is assigned
    # to one of the project or descendant versions
    def validate_no_foreign_wp_references
      version_ids = model.rolled_up_versions.select(:id)

      exists = WorkPackage
                 .where.not(project_id: model.self_and_descendants.select(:id))
                 .exists?(version_id: version_ids)

      errors.add :base, :foreign_wps_reference_version if exists
    end

    def validate_has_archive_project_permission
      validate_can_archive_project
      validate_can_archive_subprojects
    end

    def validate_can_archive_project
      return if user.allowed_in_project?(:archive_project, model)

      errors.add :base, :error_unauthorized
    end

    def validate_can_archive_subprojects
      # prevent adding another error if there is already one present
      return if errors.present?

      active_subprojects = model.active_subprojects
      return if active_subprojects.empty?
      return if user.allowed_in_project?(:archive_project, active_subprojects)

      errors.add :base, :archive_permission_missing_on_subprojects
    end
  end
end
