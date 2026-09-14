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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package filtering by Parent/Ancestor ranks exact matches first", :js, :selenium do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }

  # Same rigor technique as id_filter_ranking_spec.rb: semantic identifiers decouple which
  # string matches from the underlying id, so creation order (and hence id order) can be chosen
  # adversarially. prefix_match is created first (lower id) and is also more recently updated,
  # so default id-ascending order or updatedAt-desc alone would both rank it first if
  # exact_match sorting were broken, or the filter never actually reached the server (see
  # the "always XHR for work-package-referencing filters" fix in
  # filter-searchable-multiselect-value.component.ts).
  let!(:prefix_match) do
    create(:work_package, project:, updated_at: 1.minute.ago, skip_semantic_id_allocation: true)
  end
  let!(:exact_match) do
    create(:work_package, project:, updated_at: 2.days.ago, skip_semantic_id_allocation: true)
  end
  let!(:prefix_alias) do
    create(:work_package_semantic_alias, work_package: prefix_match, identifier: "PARENTFILTER-50")
  end
  let!(:exact_alias) do
    create(:work_package_semantic_alias, work_package: exact_match, identifier: "PARENTFILTER-5")
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  before do
    wp_table.visit!
    wp_table.expect_work_package_listed(exact_match, prefix_match)

    filters.open
  end

  it "shows the exact identifier match first in the Parent filter's dropdown" do
    filters.add_filter("Parent")

    dropdown = search_autocomplete(page.find_by_id("values-parent"),
                                   query: "#PARENTFILTER-5",
                                   results_selector: "body")

    within(dropdown) do
      option_texts = all(".ng-option").map(&:text)

      expect(option_texts.first).to include("##{exact_match.id}")
    end
  end

  it "shows the exact identifier match first in the Ancestor filter's dropdown" do
    filters.add_filter("Descendants of")

    dropdown = search_autocomplete(page.find_by_id("values-ancestor"),
                                   query: "#PARENTFILTER-5",
                                   results_selector: "body")

    within(dropdown) do
      option_texts = all(".ng-option").map(&:text)

      expect(option_texts.first).to include("##{exact_match.id}")
    end
  end
end
