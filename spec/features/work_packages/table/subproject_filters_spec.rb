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

require "spec_helper"

RSpec.describe "Subproject filters", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:parent) { create(:project) }
  shared_let(:archived) { create(:project, :archived, parent:, name: "archived project") }
  shared_let(:non_archived) { create(:project, parent:) }
  shared_let(:sibling) { create(:project, parent:, name: "Sibling subproject") }
  shared_let(:work_package) { create(:work_package, project: parent) }

  let(:wp_table) { Pages::WorkPackagesTable.new(parent) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:user) { create(:admin) }

  before do
    login_as(user)
    work_package
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  # Tests for regression #54278
  it "does not allow to select archived subprojects" do
    # Open filter menu
    filters.expect_filter_count(1)
    filters.open

    filters.add_filter("Including subproject")

    dropdown = search_autocomplete(page.find("op-project-autocompleter"),
                                   query: "archive",
                                   results_selector: ".ng-dropdown-panel-items")

    expect(dropdown).to have_no_text "archived project"
  end

  it_behaves_like "a project picker searchable by identifier" do
    let(:target_project) { sibling }
    let(:control_project) { non_archived }

    before do
      filters.expect_filter_count(1)
      filters.open

      filters.add_filter("Including subproject")
    end

    def search_project(query)
      search_autocomplete(page.find("op-project-autocompleter"),
                          query:,
                          results_selector: ".ng-dropdown-panel-items")
    end
  end
end
