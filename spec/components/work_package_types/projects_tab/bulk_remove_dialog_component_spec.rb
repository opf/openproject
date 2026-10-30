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

require "rails_helper"

RSpec.describe WorkPackageTypes::ProjectsTab::BulkRemoveDialogComponent, type: :component do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }

  before do
    render_inline(described_class.new(variant: type.default_variant, projects: Project.where(id: [bookshop, foundry])))
  end

  it "asks whether to remove the type from these projects" do
    expect(page).to have_css("h2", text: "Remove type 'Bug' from these projects?")
  end

  it "does not promise that work packages are left alone" do
    expect(page).to have_text("Projects that still have work packages of this type keep it.")
  end

  it "lists each project with the variant it uses" do
    list = find_test_selector("type-projects-bulk-list")

    expect(list).to have_link("Bookshop").and have_link("Foundry")
    expect(list).to have_text("Hardware")
  end

  it "asks for an acknowledgement before removing" do
    expect(page).to have_field("I understand that this type will no longer be available in the selected projects",
                               type: :checkbox)
    expect(page).to have_button("Remove")
  end

  it "submits every listed project" do
    expect(page).to have_field("project_ids[]", type: :hidden, with: bookshop.id.to_s)
    expect(page).to have_field("project_ids[]", type: :hidden, with: foundry.id.to_s)
  end
end
