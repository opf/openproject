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

require "support/pages/page"
require "support/pages/work_packages/abstract_work_package_create"

module Pages
  class FullWorkPackageCreate < AbstractWorkPackageCreate
    private

    def container
      find(".work-packages--show-view")
    end

    def path
      if original_work_package
        project_work_package_path(original_work_package.project, original_work_package.id) + "/copy"
      elsif parent_work_package
        new_project_work_package_path(parent_work_package.project.identifier,
                                      parent_id: parent_work_package.id)
      elsif project
        new_project_work_package_path(project.identifier)
      end
    end
  end
end
