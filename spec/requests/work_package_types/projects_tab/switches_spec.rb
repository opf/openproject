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

RSpec.describe "Switching the variant of a work package type's projects", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type:, variant_name: "Firmware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:smithy) { create(:project, name: "Smithy", types: [firmware]) }
  shared_let(:unrelated) { create(:project, name: "Unrelated", types: []) }

  before { login_as admin }

  def open_switch(*projects)
    get new_type_projects_switch_path(type_id: type.id), params: { project_ids: projects.map(&:id) }, as: :turbo_stream
  end

  def switch(*projects, to:)
    post type_projects_switch_path(type_id: type.id),
         params: { project_ids: projects.map(&:id), target_id: to.id },
         as: :turbo_stream
  end

  describe "a single project" do
    it "opens the switch dialog with its impact preview" do
      open_switch(foundry)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include(Projects::Settings::WorkPackages::Types::SwitchDialogComponent::DIALOG_ID)
        .and include("project-types-switch-impact")
    end

    it "moves the project to the chosen variant" do
      switch(foundry, to: firmware)

      expect(response).to have_http_status(:ok)
      expect(foundry.reload.type_variant(type)).to eq(firmware)
    end

    it "explains a refusal inside the dialog" do
      switch(foundry, to: hardware)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("The target type must be different from the type the project uses now")
      expect(response.body).not_to include("closeDialog")
    end
  end

  describe "several projects" do
    it "offers the type and its global variants as targets" do
      owning = create(:project, name: "Laboratory")
      create(:project_owned_type_variant, type:, project: owning, variant_name: "Prototype")

      open_switch(bookshop, foundry)

      expect(response.body).to include("Bulk switch type or variant")
        .and include("Hardware").and include("Firmware")
      expect(response.body).not_to include("Prototype")
    end

    it "asks to confirm, listing every project including one already on the target" do
      get new_type_projects_switch_confirmation_path(type_id: type.id),
          params: { project_ids: [bookshop.id, smithy.id], target_id: firmware.id },
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("closeDialog").and include("type-projects-bulk-switch-dialog")
      expect(response.body).to include("Switch type variant?").and include("Bookshop").and include("Smithy")
    end

    it "moves every project to the chosen variant" do
      switch(bookshop, foundry, to: firmware)

      expect(response).to have_http_status(:ok)
      expect(bookshop.reload.type_variant(type)).to eq(firmware)
      expect(foundry.reload.type_variant(type)).to eq(firmware)
    end

    it "treats a project already on the chosen variant as done" do
      switch(foundry, smithy, to: firmware)

      expect(response).to have_http_status(:ok)
      expect(smithy.reload.type_variant(type)).to eq(firmware)
      expect(response.body).to include("The selected projects now use Bug: Firmware.")
    end

    it "refuses a project-owned variant as the target" do
      owned = create(:project_owned_type_variant, type:, project: foundry, variant_name: "Prototype")

      switch(bookshop, foundry, to: owned)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(bookshop.reload.type_variant(type)).to eq(type.default_variant)
      expect(foundry.reload.type_variant(type)).to eq(hardware)
    end

    it "refuses another type's variant as the target" do
      switch(bookshop, foundry, to: create(:type).default_variant)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(bookshop.reload.type_variant(type)).to eq(type.default_variant)
    end

    it "leaves a project that does not use the type alone" do
      expect { switch(bookshop, unrelated, to: firmware) }
        .not_to change { unrelated.reload.project_types.pluck(:id) }

      expect(response).to have_http_status(:ok)
      expect(bookshop.reload.type_variant(type)).to eq(firmware)
    end
  end
end
