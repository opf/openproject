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

module Projects
  class ArchiveContract < ModelContract
    include Projects::Archiver

    validate :validate_no_foreign_wp_references
    validate :validate_has_archive_project_permission
    validate :validate_has_archive_project_permission

    protected

    def validate_has_archive_project_permission
      validate_can_archive_project
      validate_can_archive_subprojects
    end

    def validate_can_archive_project
      return if user.allowed_to?(:archive_project, model)

      errors.add :base, :error_unauthorized
    end

    def validate_can_archive_subprojects
      return if errors.any?

      subprojects_with_missing_permission = model.descendants.reject do |subproject|
        user.allowed_to?(:archive_project, subproject)
      end
      if subprojects_with_missing_permission.any?
        errors.add :base, :archive_permission_missing_on_subprojects
      end
    end

    def validate_model?
      false
    end
  end
end
