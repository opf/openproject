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

RSpec.describe WorkPackageTypes::ProjectsTab::BulkSwitchDialogComponent, type: :component do
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:owned) { create(:project_owned_type_variant, type:, project: foundry, variant_name: "Prototype") }

  before do
    render_inline(described_class.new(variant: type.default_variant, projects: Project.where(id: [bookshop, foundry])))
  end

  it "is titled as a bulk switch" do
    expect(page).to have_text("Bulk switch type or variant")
  end

  it "offers the type and its shared variants, never a project's own" do
    expect(page).to have_select("New type or variant", options: ["Bug", "Bug: Hardware"])
  end

  it "carries every selected project to the confirmation" do
    expect(page).to have_field("project_ids[]", type: :hidden, with: bookshop.id.to_s)
    expect(page).to have_field("project_ids[]", type: :hidden, with: foundry.id.to_s)
  end

  it "applies or cancels" do
    expect(page).to have_button("Apply").and have_button("Cancel")
  end
end
