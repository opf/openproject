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

RSpec.describe Projects::Types::Switch::DialogComponent, type: :component do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:owned) { create(:project_owned_type_variant, type: bug, project: foundry, variant_name: "Prototype") }

  let(:projects) { [bookshop, foundry] }
  let(:selected) { nil }

  before do
    render_inline(
      described_class.new(selection: Projects::Types::Switch::Selection.new(type: bug, projects:, user: admin),
                          confirmation_url: "/confirm", impact_url: "/impact",
                          params: { project_ids: projects.map(&:id) }, **{ selected: }.compact)
    )
  end

  it "is titled as a switch" do
    expect(page).to have_text("Bug: Switch variant")
  end

  it "offers several projects the type and its shared variants, never a project's own" do
    expect(page).to have_select("New type or variant", options: ["Bug", "Bug: Hardware"])
  end

  it "carries the given parameters to the confirmation" do
    expect(page).to have_field("project_ids[]", type: :hidden, with: bookshop.id.to_s)
    expect(page).to have_field("project_ids[]", type: :hidden, with: foundry.id.to_s)
  end

  it "asks the given URLs for its preview and its confirmation" do
    expect(page).to have_css("form[action='/confirm'][data-refresh-on-form-changes-turbo-stream-url-value='/impact']")
  end

  it "applies or cancels" do
    expect(page).to have_button("Apply").and have_button("Cancel")
  end

  context "with a single project" do
    let(:projects) { [foundry] }

    it "offers its own variants too, starting from the one it uses" do
      expect(page).to have_select("New type or variant", options: ["Bug", "Bug: Hardware", "Bug: Prototype"],
                                                         selected: "Bug: Hardware")
    end

    context "when asked about one of them" do
      let(:selected) { owned }

      it "opens on it" do
        expect(page).to have_select("New type or variant", selected: "Bug: Prototype")
      end
    end
  end
end
