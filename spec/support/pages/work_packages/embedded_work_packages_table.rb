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
require 'support/pages/work_packages/work_packages_table'
require 'support/components/ng_select_autocomplete_helpers.rb'

module Pages
  class EmbeddedWorkPackagesTable < WorkPackagesTable
    include ::Components::NgSelectAutocompleteHelpers

    attr_reader :container

    def initialize(container, project = nil)
      super(project)
      @container = container
    end

    def table_container
      container.find('.work-package-table')
    end

    def click_reference_inline_create
      ##
      # When using the inline create on initial page load,
      # there is a delay on travis where inline create can be clicked.
      sleep 1
      container.find('.wp-inline-create--reference-link').click

      # Returns the autocomplete container
      container.find('.wp-relations--autocomplete')
    end

    def reference_work_package(work_package, query: work_package.subject)
      click_reference_inline_create

      autocomplete_container = container.find('.wp-relations--autocomplete')
      select_autocomplete autocomplete_container,
                          query: query,
                          results_selector: '.ng-dropdown-panel-items'

      expect_work_package_listed work_package
    end
  end
end
