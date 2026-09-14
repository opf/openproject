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

RSpec.describe "Work package Parent field ranks exact matches first", :js, :selenium do
  let(:project) { create(:project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages manage_subtasks]) }

  let!(:child_work_package) { create(:work_package, project:) }

  let!(:prefix_match) do
    create(:work_package, project:, updated_at: 1.minute.ago, skip_semantic_id_allocation: true)
  end
  let!(:exact_match) do
    create(:work_package, project:, updated_at: 2.days.ago, skip_semantic_id_allocation: true)
  end
  let!(:prefix_alias) do
    create(:work_package_semantic_alias, work_package: prefix_match, identifier: "PARENTFIELD-50")
  end
  let!(:exact_alias) do
    create(:work_package_semantic_alias, work_package: exact_match, identifier: "PARENTFIELD-5")
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  before do
    query_props = { c: %w[id subject parent], t: "id:asc", hi: false }.to_json
    wp_table.visit_with_params("query_props=#{CGI.escape(query_props)}")
    wp_table.expect_work_package_listed(child_work_package, prefix_match, exact_match)
  end

  it "shows the exact identifier match first in the Parent field's dropdown" do
    field = wp_table.edit_field(child_work_package, :parent)
    field.activate!

    dropdown = field.autocomplete("#PARENTFIELD-5", select: false)
    expect(dropdown).to have_css(".ng-option", text: exact_match.subject)

    within(dropdown) do
      # Both matches must be rendered before the options are read, otherwise the
      # snapshot can be taken while the dropdown still shows the previous results.
      expect(page).to have_css(".ng-option", text: exact_match.subject)
      expect(page).to have_css(".ng-option", text: prefix_match.subject)

      # The first option is always a "-" (clear/no-parent) entry, unrelated to ranking.
      # This autocompleter's options only render the work package's subject, not its id.
      candidate_texts = all(".ng-option").map(&:text).reject { |text| text == "-" }

      expect(candidate_texts.first).to eq(exact_match.subject)
    end
  end
end
