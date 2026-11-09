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

RSpec.describe "Adding and removing a work package type's projects", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type: bug, variant_name: "Firmware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:unrelated) { create(:project, name: "Unrelated", types: []) }

  let(:user) { admin }

  before { login_as user }

  def uses_type?(project) = project.reload.project_types.exists?(type_id: bug.id)

  def switch_dialog_id = WorkPackageTypes::ProjectsTab::SwitchConfirmDialogComponent::DIALOG_ID

  # The dialog arrives inside a turbo-stream template, whose contents Capybara does not enter.
  def streamed_dialog = Capybara.string(Nokogiri::HTML5.fragment(response.body).css("template").inner_html)

  describe "GET link/new" do
    subject do
      get new_type_projects_link_path(type_id: bug.id, **wizard_flag), as: :turbo_stream
    end

    let(:wizard_flag) { {} }

    it "opens the add projects dialog" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(WorkPackageTypes::ProjectsTab::AddFormComponent::DIALOG_ID)
    end

    context "when opened from the creation wizard" do
      let(:wizard_flag) { { wizard: true } }

      it "submits the picked projects back to the wizard" do
        subject

        expect(response.body).to include(%(action="#{type_projects_link_path(type_id: bug.id, wizard: true)}"))
      end
    end
  end

  describe "GET link/candidates" do
    subject do
      get type_projects_link_candidates_path(type_id: bug.id), params: { name: "project_ids", query: }.compact
    end

    shared_let(:estate) { create(:project, name: "Estate") }
    shared_let(:annex) { create(:project, name: "Annex", parent: estate) }

    let(:query) { nil }

    it "renders the project tree the dialog picks from" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Estate").and include("Annex")
    end

    context "with a query" do
      let(:query) { "Annex" }

      it "narrows to the matches and the branches leading to them" do
        subject

        expect(response.body).to include("Annex").and include("Estate")
      end

      it "leaves out projects that match nothing" do
        subject

        expect(response.body).not_to include("Unrelated")
      end
    end

    context "with a query naming a project's identifier" do
      let(:query) { "libris" }

      before { create(:project, name: "Archive", identifier: "libris-nova") }

      it "matches the project" do
        subject

        expect(response.body).to include("Archive")
      end
    end
  end

  describe "POST link" do
    subject do
      post path,
           params: { project_ids:,
                     include_sub_items: include_sub_items ? "1" : "0",
                     confirm_switch: confirm_switch ? "1" : "0" },
           as: :turbo_stream
    end

    shared_let(:depot) { create(:project, name: "Depot") }
    shared_let(:laboratory) { create(:project, name: "Laboratory", types: [firmware]) }

    let(:path) { type_variant_projects_link_path(type_id: bug.id, variant_id: hardware.id) }
    let(:projects) { [depot] }
    let(:project_ids) { projects.map { { nodeId: it.id.to_s }.to_json } }
    let(:include_sub_items) { false }
    let(:confirm_switch) { false }

    it "adds the projects without asking" do
      subject

      expect(response.body).not_to include(switch_dialog_id)
      expect(depot.reload.type_variant(bug)).to eq(hardware)
    end

    context "on the type's own tab" do
      let(:path) { type_projects_link_path(type_id: bug.id) }

      it "puts the projects on the type's base variant" do
        subject

        expect(response).to have_http_status(:ok)
        expect(depot.reload.type_variant(bug)).to eq(bug.default_variant)
      end
    end

    context "with a payload naming no project" do
      let(:project_ids) { ["not json"] }

      it "is refused" do
        subject

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with an empty selection" do
      let(:project_ids) { [] }

      it "is refused with a hint" do
        subject

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Please select at least one project.")
      end
    end

    context "when a project is on another variant of the type" do
      let(:projects) { [laboratory, depot] }

      it "asks before switching it" do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(switch_dialog_id).and include("Laboratory")
        expect(laboratory.reload.type_variant(bug)).to eq(firmware)
      end

      it "keeps the project picker open underneath while asking" do
        subject

        expect(response.body).not_to include(%(action="closeDialog"))
      end

      it "adds nothing else while asking" do
        subject

        expect(depot.reload.project_types.where(type_id: bug.id)).to be_empty
      end

      it "lists only the projects that would switch" do
        subject

        expect(response.body).not_to include("Depot")
      end

      context "when confirmed" do
        let(:confirm_switch) { true }

        it "switches it and adds the others" do
          subject

          expect(response.body).to include(%(action="closeDialog" target="#{switch_dialog_id}"))
          expect(laboratory.reload.type_variant(bug)).to eq(hardware)
          expect(depot.reload.type_variant(bug)).to eq(hardware)
        end

        it "switches it over rather than adding a second row" do
          subject

          expect(laboratory.project_types.where(type_id: bug.id).count).to eq(1)
        end
      end
    end

    context "when submitted from the creation wizard" do
      let(:path) { type_variant_projects_link_path(type_id: bug.id, variant_id: hardware.id, wizard: true) }

      context "with an empty selection" do
        let(:project_ids) { [] }

        it "keeps the refused form in the wizard" do
          subject

          expect(response.body).to include(%(action="#{path}"))
        end
      end

      context "when a project is on another variant of the type" do
        let(:projects) { [laboratory, depot] }

        it "keeps the confirmation in the wizard" do
          subject

          expect(response.body).to include(switch_dialog_id).and include(%(action="#{path}"))
        end
      end
    end

    context "with sub-items included" do
      let(:include_sub_items) { true }
      let(:shed) { create(:project, name: "Shed") }
      let(:annex_types) { [] }
      let!(:annex) { create(:project, name: "Annex", parent: shed, types: annex_types) }
      let(:projects) { [shed] }

      it "reaches the sub-projects too" do
        subject

        expect(annex.reload.type_variant(bug)).to eq(hardware)
      end

      context "when a sub-project already applies the variant" do
        let(:annex_types) { [hardware] }

        it "is nothing to do rather than a conflict" do
          subject

          expect(response).to have_http_status(:ok)
          expect(shed.reload.type_variant(bug)).to eq(hardware)
          expect(annex.reload.type_variant(bug)).to eq(hardware)
        end
      end

      context "when a sub-project is on another variant of the type" do
        let(:annex_types) { [firmware] }

        it "asks about it, without listing the parent" do
          subject

          expect(response.body).to include(switch_dialog_id).and include("Annex")
          expect(response.body).not_to include("Shed")
        end

        it "carries the sub-projects into the confirmation, as it is resubmitted without the sub-items flag" do
          subject

          node_ids = streamed_dialog.all("input[name='project_ids[]']", visible: :all).map { JSON.parse(it.value)["nodeId"] }
          expect(node_ids).to contain_exactly(shed.id.to_s, annex.id.to_s)
        end

        context "when confirmed" do
          let(:confirm_switch) { true }

          it "still moves it" do
            subject

            expect(response).to have_http_status(:ok)
            expect(annex.reload.type_variant(bug)).to eq(hardware)
          end
        end
      end
    end

    context "when part of the selection is refused" do
      shared_let(:blocked) { create(:project, name: "Blocked") }

      let(:projects) { [depot, blocked] }

      before do
        refusal = ServiceResult.failure(result: blocked)
        refusal.errors.add(:base, "Refused for a reason")

        allow(Projects::Types::AddService).to receive(:new).and_call_original
        allow(Projects::Types::AddService)
          .to receive(:new).with(user: anything, model: blocked)
          .and_return(instance_double(Projects::Types::AddService, call: refusal))
      end

      it "closes the dialog anyway" do
        subject

        expect(response.body).to include("dialog").and include("closeDialog")
      end

      it "reloads the project list anyway" do
        subject

        expect(response.body).to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
      end

      it "reports the refusal" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Blocked")
      end
    end
  end

  describe "DELETE link" do
    subject do
      delete type_projects_link_path(type_id: bug.id), params: { project_ids: projects.map(&:id) }, as: :turbo_stream
    end

    let(:projects) { [bookshop, foundry] }

    it "removes the type from every given project" do
      subject

      expect(response).to have_http_status(:ok)
      expect(uses_type?(bookshop)).to be(false)
      expect(uses_type?(foundry)).to be(false)
    end

    it "closes the confirmation and reloads the project list" do
      subject

      expect(response.body).to include("closeDialog").and include("type-projects-bulk-remove-dialog")
      expect(response.body).to include(WorkPackageTypes::ReloadableConfigurationFrameComponent::RELOAD_EVENT_NAME)
    end

    context "when one project still has work packages of the type" do
      before { create(:work_package, project: foundry, type: bug) }

      it "removes the type from the others" do
        subject

        expect(uses_type?(bookshop)).to be(false)
      end

      it "keeps the type in the blocked project and names it" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(uses_type?(foundry)).to be(true)
        expect(response.body).to include("Foundry")
      end

      it "links to the work packages standing in the way" do
        subject

        expect(response.body)
          .to include(CGI.escapeHTML(work_packages_path(query_props: { f: [
            { n: "type", o: "=", v: [bug.id] },
            { n: "project", o: "=", v: [foundry.id.to_s] }
          ] }.to_json)))
      end

      context "when another project is refused for a different reason" do
        before do
          refusal = ServiceResult.failure(result: bookshop)
          refusal.errors.add(:base, "Refused for a reason")

          allow(Projects::Types::RemoveService).to receive(:new).and_call_original
          allow(Projects::Types::RemoveService)
            .to receive(:new).with(user: anything, model: bookshop)
            .and_return(instance_double(Projects::Types::RemoveService, call: refusal))
        end

        it "reports that refusal as well" do
          subject

          expect(response.body).to include("Bookshop: Refused for a reason")
        end
      end
    end

    context "with a project that does not use the type" do
      let(:projects) { [bookshop, unrelated] }

      before { create(:work_package, project: unrelated, type: bug) }

      it "ignores it" do
        expect { subject }.not_to change { unrelated.reload.project_types.pluck(:id) }

        expect(uses_type?(bookshop)).to be(false)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Unrelated")
      end
    end

    context "without admin access" do
      let(:user) { create(:user) }

      it "is refused" do
        subject

        expect(response).to have_http_status(:forbidden)
        expect(uses_type?(bookshop)).to be(true)
      end
    end
  end

  describe "GET link/deletion/new" do
    subject do
      get new_type_projects_link_deletion_path(type_id: bug.id, **wizard_flag),
          params: { project_ids: [bookshop.id, foundry.id] },
          as: :turbo_stream
    end

    let(:wizard_flag) { {} }

    it "asks to confirm the removal, listing the projects with their variants" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Remove type &#39;Bug&#39; from these projects?")
        .and include("Bookshop").and include("Foundry").and include("Hardware")
    end

    context "when opened from the creation wizard" do
      let(:wizard_flag) { { wizard: true } }

      it "removes the type from within the wizard" do
        subject

        expect(response.body).to include(%(action="#{type_projects_link_path(type_id: bug.id, wizard: true)}"))
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
end
