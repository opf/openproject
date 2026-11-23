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

RSpec.describe "The row menu of a work package type's projects", type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:unrelated) { create(:project, name: "Unrelated", types: []) }

  let(:user) { admin }
  let(:ids) { [bookshop.id, foundry.id] }
  let(:menu) { Capybara.string(response.body).find("ul[role='menu']") }

  before { login_as user }

  subject { get type_projects_menu_path(type_id: bug.id), params: { ids:, invoker_id: foundry.id } }

  it "acts on every selected project" do
    subject

    expect(response).to have_http_status(:ok)
    expect(menu["data-sortable-lists-scope-count"]).to eq("2")
    expect(menu).to have_link("Remove type from these projects")
  end

  context "when a selected project no longer uses the type" do
    let(:ids) { [unrelated.id, foundry.id] }

    it "acts on the invoking project alone" do
      subject

      expect(menu["data-sortable-lists-scope-count"]).to eq("1")
      expect(menu).to have_link("Remove type from this project")
    end
  end

  context "when the invoking project no longer uses the type" do
    subject { get type_projects_menu_path(type_id: bug.id), params: { ids: [unrelated.id], invoker_id: unrelated.id } }

    it "is not found" do
      subject

      expect(response).to have_http_status(:not_found)
    end
  end

  context "without admin access" do
    let(:user) { create(:user) }

    it "is refused" do
      subject

      expect(response).to have_http_status(:forbidden)
    end
  end
end
