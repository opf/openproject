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

require 'support/pages/page'
require 'support/pages/work_packages/abstract_work_package_create'

module Pages
  class SplitWorkPackageCreate < AbstractWorkPackageCreate
    def initialize(project:, original_work_package: nil, parent_work_package: nil)
      super(original_work_package: original_work_package,
            parent_work_package: parent_work_package,
            project: project)
    end

    def container
      find('.work-packages--new')
    end

    private

    def path
      if original_work_package
        project_work_packages_path(project) + "/details/#{original_work_package.id}/copy"
      else
        path = project_work_packages_path(project) + '/create_new'
        path += "?parent_id=#{parent_work_package.id}" if parent_work_package

        path
      end
    end
  end
end
