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

RSpec.describe TestManagement::TestCasesHelper do
  let(:project) { create(:project) }
  let!(:root) { create(:tm_suite, project:) }
  let!(:child) { create(:tm_suite, project:, parent: root) }

  describe "#tm_suite_count" do
    it "adds the counts of the subfolders" do
      counts = { root.id => 1, child.id => 2 }

      expect(helper.tm_suite_count(root, suite_counts: counts, suites: [root, child])).to eq(3)
      expect(helper.tm_suite_count(child, suite_counts: counts, suites: [root, child])).to eq(2)
    end
  end

  describe "#tm_render_suite_nodes" do
    it "nests subfolders and marks the selected one" do
      html = Capybara.string(
        helper.safe_join(
          helper.tm_render_suite_nodes(project:, suites: [root, child], suite_counts: {}, current_suite_id: child.id)
        )
      )

      expect(html).to have_css("[data-test-selector='tm-folder-node-#{root.id}'] " \
                               "[data-test-selector='tm-folder-node-#{child.id}']")
      expect(html).to have_css("[data-test-selector='tm-folder-#{child.id}'].is-selected")
      expect(html).to have_no_css("[data-test-selector='tm-folder-#{root.id}'].is-selected")
    end
  end

  it "renders priority and status markers" do
    expect(helper.tm_priority_label("high")).to include("tm-priority-high")
    expect(helper.tm_status_label("ready")).to include("tm-status-ready")
    expect(helper.tm_unknown).to include("color-fg-muted")
  end
end
