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

RSpec.describe Projects::Types::Switch::ConfirmDialogComponent, type: :component do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }

  let(:listed_projects) { [bookshop, foundry] }

  before do
    render_inline(
      described_class.new(target: hardware, url: "/switch", params: { project_ids: [bookshop.id, foundry.id] },
                          listed_projects:)
    )
  end

  it "says what the switch hides, naming the variant it switches to" do
    expect(page).to have_css("h2", text: "Switch type variant?")
    expect(page).to have_text("Switching to Bug: Hardware hides the fields it does not include. " \
                              "Their values are kept, but will no longer be visible.")
  end

  it "introduces the listed projects" do
    expect(page).to have_text("The following projects will switch:")
  end

  it "lists the given projects" do
    list = find_test_selector("type-projects-list")

    expect(list).to have_link("Bookshop").and have_link("Foundry")
  end

  context "with a single listed project" do
    let(:listed_projects) { [foundry] }

    it "introduces it" do
      expect(page).to have_text("The following project will switch:")
    end
  end

  context "without any listed project" do
    let(:listed_projects) { [] }

    it "lists nothing" do
      expect(page).to have_no_test_selector("type-projects-list")
      expect(page).to have_no_text("will switch")
    end
  end

  it "asks for an acknowledgement before switching" do
    expect(page).to have_field(
      "I understand that fields the new variant does not include will be hidden, along with their values",
      type: :checkbox
    )
    expect(page).to have_button("Switch")
  end

  it "submits to the given URL" do
    expect(page).to have_css("form[action='/switch'][method='post']")
  end

  it "submits the target and the given parameters" do
    expect(page).to have_field("target_id", type: :hidden, with: hardware.id.to_s)
    expect(page).to have_field("project_ids[]", type: :hidden, with: bookshop.id.to_s)
    expect(page).to have_field("project_ids[]", type: :hidden, with: foundry.id.to_s)
  end
end
