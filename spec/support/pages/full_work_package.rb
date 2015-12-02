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
  class FullWorkPackage < Page
    attr_reader :work_package

    def initialize(work_package)
      @work_package = work_package
    end

    def expect_subject
      within(container) do
        expect(page).to have_content(work_package.subject)
      end
    end

    def expect_current_path
      current_path = URI.parse(current_url).path
      expect(current_path).to eql path
    end

    def ensure_page_loaded
      expect(page).to have_selector('.work-package-details-activities-activity-contents .user',
                                    text: work_package.journals.last.user.name)
    end

    def expect_attributes(attribute_expectations)
      attribute_expectations.each do |label_name, value|
        expect(page).to have_selector('.attributes-key-value--key', text: label_name.to_s)

        dl_element = page.find('.attributes-key-value--key', text: label_name.to_s).parent

        expect(dl_element).to have_selector('.attributes-key-value--value-container', text: value)
      end
    end

    def visit_tab!(tab)
      visit path(tab)
    end

    private

    def container
      find('.work-packages--show-view')
    end

    def path(tab='activity')
      work_package_path(work_package.id, tab)
    end
  end
end
