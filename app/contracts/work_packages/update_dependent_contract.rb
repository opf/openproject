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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Disables ordinary attribute validations (a descendant's type/status/custom fields may no
# longer fit the project it is cascaded into) but still allows to be queried for assignable_*
# (e.g. statuses) that are necessary whenever a dependent (e.g. descendant of a work package)
# is moved to a project where the type is switched.
#
# Authorization is not skipped, though: the descendant must still be visible to the user, and
# they still need move_work_packages in its current (not yet saved) project. This is what
# WorkPackages::UpdateService relies on to decide which descendants actually get cascaded.
module WorkPackages
  class UpdateDependentContract < UpdateContract
    def validate
      user_allowed_to_access
      user_allowed_to_move_from_source_project
      errors.empty?
    end
  end
end
