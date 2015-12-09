#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'

module Pages
  class SplitWorkPackageCreate < Page
    attr_reader :work_package,
                :project

    def initialize(project, work_package = nil)
      # in case of copy, the original work package can be provided
      @work_package = work_package
      @project = project
    end

    def expect_fully_loaded
      expect(page).to have_field(I18n.t('js.work_packages.properties.subject'))
    end

    def update_attributes(attribute_map)
      # Only designed for text fields for now
      attribute_map.each do |label, value|
        fill_in(label, with: value)
      end
    end

    def save!
      click_button I18n.t('js.button_save')
    end

    private

    def path
      if work_package
        project_work_packages_path(project) + "/details/#{work_package.id}/copy"
      else
        project_work_packages_path(project) + '/create_new'
      end
    end
  end
end
