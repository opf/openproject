#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/abstract_work_package'
require 'support/pages/split_work_package_create'

module Pages
  class SplitWorkPackage < Pages::AbstractWorkPackage
    attr_reader :selector

    def initialize(work_package, project = nil)
      super work_package, project
      @selector = '.work-packages--details'
    end

    def edit_field(attribute)
      super(attribute, container)
    end

    def switch_to_tab(tab:)
      find('.tabrow li a', text: tab.upcase).click
    end

    def switch_to_fullscreen
      find('.work-packages--details-fullscreen-icon').click
      FullWorkPackage.new(work_package, project)
    end

    def closed?
      expect(page).not_to have_selector(@selector)
    end

    private

    def container
      find(@selector)
    end

    def path(tab = 'overview')
      state = "#{work_package.id}/#{tab}"

      if project
        project_work_packages_path(project, "details/#{state}")
      else
        details_work_packages_path(state)
      end
    end

    def create_page(args)
      args.merge!(project: project || work_package.project)
      SplitWorkPackageCreate.new(args)
    end
  end
end
