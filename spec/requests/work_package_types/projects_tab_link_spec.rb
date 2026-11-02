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

RSpec.describe "Adding projects to a work package type variant", :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type:, variant_name: "Firmware") }

  before { login_as admin }

  def link_projects(*projects, variant: hardware, include_sub_items: false, confirm_switch: false)
    post link_type_variant_projects_path(type_id: type.id, variant_id: variant.id),
         params: { project_ids: projects.map { { nodeId: it.id.to_s }.to_json },
                   include_sub_items: include_sub_items ? "1" : "0",
                   confirm_switch: confirm_switch ? "1" : "0" },
         as: :turbo_stream
  end

  def switch_dialog_id = WorkPackageTypes::ProjectsTab::SwitchConfirmDialogComponent::DIALOG_ID

  # The dialog arrives inside a turbo-stream template, whose contents Capybara does not enter.
  def streamed_dialog = Capybara.string(Nokogiri::HTML5.fragment(response.body).css("template").inner_html)

  describe "a project that already applies the variant" do
    it "is nothing to do rather than a conflict" do
      parent = create(:project)
      child = create(:project, parent:, types: [hardware])

      link_projects(parent, include_sub_items: true)

      expect(response).to have_http_status(:ok)
      expect(parent.reload.type_variant(type)).to eq(hardware)
      expect(child.reload.type_variant(type)).to eq(hardware)
    end

    it "still moves a child sitting on another variant of the same type" do
      parent = create(:project)
      child = create(:project, parent:, types: [firmware])

      link_projects(parent, include_sub_items: true, confirm_switch: true)

      expect(response).to have_http_status(:ok)
      expect(child.reload.type_variant(type)).to eq(hardware)
    end
  end

  describe "a project on another variant of the type" do
    shared_let(:laboratory) { create(:project, name: "Laboratory", types: [firmware]) }
    shared_let(:depot) { create(:project, name: "Depot") }

    it "asks before switching it" do
      link_projects(laboratory, depot)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(switch_dialog_id).and include("Laboratory")
      expect(laboratory.reload.type_variant(type)).to eq(firmware)
    end

    it "keeps the project picker open underneath while asking" do
      link_projects(laboratory, depot)

      expect(response.body).not_to include(%(action="closeDialog"))
    end

    it "adds nothing else while asking" do
      link_projects(laboratory, depot)

      expect(depot.reload.project_types.where(type_id: type.id)).to be_empty
    end

    it "lists only the projects that would switch" do
      link_projects(laboratory, depot)

      expect(response.body).not_to include("Depot")
    end

    it "asks about a sub-project brought in with its parent, without listing the parent" do
      parent = create(:project, name: "Shed")
      create(:project, name: "Annex", parent:, types: [firmware])

      link_projects(parent, include_sub_items: true)

      expect(response.body).to include(switch_dialog_id).and include("Annex")
      expect(response.body).not_to include("Shed")
    end

    it "carries the sub-projects into the confirmation, as it is resubmitted without the sub-items flag" do
      parent = create(:project)
      child = create(:project, parent:, types: [firmware])

      link_projects(parent, include_sub_items: true)

      node_ids = streamed_dialog.all("input[name='project_ids[]']", visible: :all).map { JSON.parse(it.value)["nodeId"] }
      expect(node_ids).to contain_exactly(parent.id.to_s, child.id.to_s)
    end

    it "switches it once confirmed" do
      link_projects(laboratory, depot, confirm_switch: true)

      expect(response.body).to include(%(action="closeDialog" target="#{switch_dialog_id}"))
      expect(laboratory.reload.type_variant(type)).to eq(hardware)
      expect(depot.reload.type_variant(type)).to eq(hardware)
    end
  end

  describe "a selection with no project on another variant" do
    it "is added without asking" do
      project = create(:project)

      link_projects(project)

      expect(response.body).not_to include(switch_dialog_id)
      expect(project.reload.type_variant(type)).to eq(hardware)
    end
  end

  describe "when part of the selection is refused" do
    shared_let(:blocked) { create(:project, name: "Blocked") }
    shared_let(:addable) { create(:project, name: "Addable") }

    before do
      refusal = ServiceResult.failure(result: blocked)
      refusal.errors.add(:base, "Refused for a reason")

      allow(Projects::Types::AddService).to receive(:new).and_call_original
      allow(Projects::Types::AddService)
        .to receive(:new).with(user: anything, model: blocked)
        .and_return(instance_double(Projects::Types::AddService, call: refusal))
    end

    it "closes the dialog anyway" do
      link_projects(addable, blocked)

      expect(response.body).to include("dialog").and include("closeDialog")
    end

    it "repaints the project list anyway" do
      link_projects(addable, blocked)

      expect(response.body).to include(%(target="#{WorkPackageTypes::ProjectsTab::TableComponent.wrapper_key}"))
    end

    it "reports the refusal" do
      link_projects(addable, blocked)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Blocked")
    end
  end
end
