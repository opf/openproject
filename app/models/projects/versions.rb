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

module Projects::Versions
  extend ActiveSupport::Concern

  included do
    # Closes open and locked project versions that are completed
    def close_completed_versions
      Version.transaction do
        versions.where(status: %w(open locked)).find_each do |version|
          if version.completed?
            version.update_attribute(:status, "closed")
          end
        end
      end
    end

    # Returns a scope of the Versions on subprojects
    def rolled_up_versions
      Version.rolled_up(self)
    end

    # Returns a scope of the Versions used by the project
    def shared_versions
      Version.shared_with(self)
    end

    # Returns all versions a work package can be assigned to.  Opposed to
    # #shared_versions this returns an array of Versions, not a scope.
    #
    # The main benefit is in scenarios where work packages' projects are eager
    # loaded.  Because eager loading the project e.g. via
    # WorkPackage.includes(:project).where(type: 5) will assign the same instance
    # (same object_id) for every work package having the same project this will
    # reduce the number of db queries when performing operations including the
    # project's versions.
    #
    # For custom fields configured with "Allow non-open versions" this can be called
    # with only_open: false, in which case locked and closed versions are returned as well.
    def assignable_versions(only_open: true)
      if only_open
        @assignable_versions ||=
          shared_versions.references(:project).with_status_open.order_by_semver_name.to_a
      else
        @assignable_versions_including_non_open ||= # rubocop:disable Naming/MemoizedInstanceVariableName
          shared_versions.references(:project).order_by_semver_name.to_a
      end
    end
  end
end
