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

RSpec.describe WorkPackageTypes::ProjectsTab::SwitchConfirmDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type:, variant_name: "Firmware") }

  shared_let(:laboratory) { create(:project, name: "Laboratory", types: [firmware]) }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:depot) { create(:project, name: "Depot") }

  let(:switching) { ProjectType.where(type:, project: [laboratory, bookshop]) }
  let(:link_path) { link_type_variant_projects_path(type_id: type.id, variant_id: hardware.id) }
  let(:url) { link_path }
  let(:project_ids) { [laboratory.id, bookshop.id, depot.id] }

  before do
    render_inline(described_class.new(variant: hardware, switching:, url:, project_ids:))
  end

  it "asks to replace the other variants with this one" do
    expect(page).to have_text(
      'The following projects already use other variants for Bug. Are you sure you want to replace them with "Hardware"? ' \
      "This will affect forms and workflows in all of these projects."
    )
  end

  it "lists each switching project with the variant it uses now" do
    list = page.find(:test_id, "type-projects-switching")

    expect(list).to have_text("Laboratory").and have_text("Firmware")
    expect(list).to have_text("Bookshop").and have_text("Bug")
    expect(list).to have_no_text("Depot")
  end

  it "confirms with Change" do
    expect(page).to have_button("Change")
    expect(page).to have_button("Cancel")
  end

  it "resubmits the whole selection to the link action, confirmed" do
    form = page.find("form[action='#{link_path}']")

    node_ids = form.all("input[name='project_ids[]']", visible: :all).map { JSON.parse(it.value)["nodeId"] }
    expect(node_ids).to contain_exactly(laboratory.id.to_s, bookshop.id.to_s, depot.id.to_s)
    expect(form).to have_field("confirm_switch", with: "1", type: :hidden)
  end

  context "when every project is being enabled" do
    let(:url) { enable_all_type_variant_projects_path(type_id: type.id, variant_id: hardware.id, value: "1") }
    let(:project_ids) { [] }

    it "resubmits to that action, confirmed, with no selection to carry" do
      form = page.find("form[action='#{url}']")

      expect(form).to have_no_field("project_ids[]", type: :hidden)
      expect(form).to have_field("confirm_switch", with: "1", type: :hidden)
    end
  end
end
