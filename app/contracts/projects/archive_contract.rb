#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects
  class ArchiveContract < ModelContract
    def validate
      user_allowed
      validate_no_foreign_wp_references

      super
    end

    protected

    def user_allowed
      unless authorized?
        errors.add :base, :error_unauthorized
      end
    end

    # Check that there is no wp of a non descendant project that is assigned
    # to one of the project or descendant versions
    def validate_no_foreign_wp_references
      version_ids = model.rolled_up_versions.select(:id)

      exists = WorkPackage
               .where.not(project_id: model.self_and_descendants.select(:id))
               .where(version_id: version_ids)
               .exists?

      errors.add :base, :foreign_wps_reference_version if exists
    end

    def validate_model?
      false
    end

    def authorized?
      user.admin?
    end
  end
end
