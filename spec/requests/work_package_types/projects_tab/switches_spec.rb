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
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type: bug, variant_name: "Hardware") }
  shared_let(:firmware) { create(:type_variant, type: bug, variant_name: "Firmware") }

  shared_let(:bookshop) { create(:project, name: "Bookshop", types: [bug]) }
  shared_let(:foundry) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:forge) { create(:project, name: "Forge", types: [hardware]) }
  shared_let(:smithy) { create(:project, name: "Smithy", types: [firmware]) }
  shared_let(:unrelated) { create(:project, name: "Unrelated", types: []) }

  before { login_as admin }

  describe "GET switch/new" do
    subject do
      get new_type_projects_switch_path(type_id: bug.id),
          params: { project_ids: projects.map(&:id) },
          as: :turbo_stream
    end

    let(:projects) { [foundry] }

    before { create(:project_owned_type_variant, type: bug, project: foundry, variant_name: "Prototype") }

    it "offers a single project its own variants too" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bug: Switch variant").and include("Prototype").and include("Firmware")
    end

    it "wires the live impact preview" do
      subject

      expect(response.body).to include(CGI.escapeHTML(type_projects_switch_impact_path(type_id: bug.id)))
    end

    context "with several projects" do
      let(:projects) { [bookshop, foundry] }

      it "offers the shared variants only" do
        subject

        expect(response.body).to include("Hardware").and include("Firmware")
        expect(response.body).not_to include("Prototype")
      end
    end

    context "when no selected project uses the type" do
      let(:projects) { [unrelated] }

      it "is not found" do
        subject

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET switch/confirmation/new" do
    subject do
      get new_type_projects_switch_confirmation_path(type_id: bug.id),
          params: { project_ids: projects.map(&:id), target_id: target.id },
          as: :turbo_stream
    end

    let(:projects) { [foundry] }
    let(:target) { firmware }

    it "asks to confirm switching a single project" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("closeDialog").and include("type-variant-switch-dialog")
      expect(response.body).to include("Switch type variant?").and include("Foundry")
    end

    context "when the project already uses the target" do
      let(:target) { hardware }

      it "refuses inside the dialog, without asking to confirm" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("The project already uses this type or variant.")
        expect(response.body).not_to include("Switch type variant?")
      end
    end

    context "when every selected project already uses the target" do
      let(:projects) { [foundry, forge] }
      let(:target) { hardware }

      it "refuses inside the dialog" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("The selected projects already use this type or variant.")
      end
    end

    context "when only one of several differently-set projects already uses the target" do
      let(:projects) { [bookshop, smithy] }

      it "asks to confirm, listing only the project that will switch" do
        subject

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Switch type variant?").and include("Bookshop")
        expect(response.body).not_to include("Smithy")
      end
    end
  end

  describe "POST switch" do
    subject do
      post type_projects_switch_path(type_id: bug.id),
           params: { project_ids: projects.map(&:id), target_id: target.id },
           as: :turbo_stream
    end

    let(:projects) { [foundry] }
    let(:target) { firmware }

    it "moves the project to the chosen variant" do
      subject

      expect(response).to have_http_status(:ok)
      expect(foundry.reload.type_variant(bug)).to eq(firmware)
      expect(response.body).to include("The project now uses Bug: Firmware.")
    end

    context "when the project already uses the target" do
      let(:target) { hardware }

      it "is refused" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("The project already uses this type or variant.")
      end
    end

    context "when the target is the project's own variant" do
      let(:target) { create(:project_owned_type_variant, type: bug, project: foundry, variant_name: "Prototype") }

      it "moves the project to it" do
        subject

        expect(response).to have_http_status(:ok)
        expect(foundry.reload.type_variant(bug)).to eq(target)
      end
    end

    context "when the target is another project's own variant" do
      let(:target) { create(:project_owned_type_variant, type: bug, project: bookshop, variant_name: "Prototype") }

      it "is refused" do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(foundry.reload.type_variant(bug)).to eq(hardware)
      end
    end

    context "with several projects" do
      let(:projects) { [bookshop, foundry] }

      it "moves every project to the chosen variant" do
        subject

        expect(response).to have_http_status(:ok)
        expect(bookshop.reload.type_variant(bug)).to eq(firmware)
        expect(foundry.reload.type_variant(bug)).to eq(firmware)
      end

      context "when every one is already on the target" do
        let(:projects) { [foundry, forge] }
        let(:target) { hardware }

        it "is refused" do
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("The selected projects already use this type or variant.")
        end
      end

      context "when one is already on the target" do
        let(:projects) { [foundry, smithy] }

        it "treats it as done" do
          subject

          expect(response).to have_http_status(:ok)
          expect(smithy.reload.type_variant(bug)).to eq(firmware)
          expect(response.body).to include("The selected projects now use Bug: Firmware.")
        end
      end

      context "when the target is a project-owned variant" do
        let(:target) { create(:project_owned_type_variant, type: bug, project: foundry, variant_name: "Prototype") }

        it "is refused" do
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(bookshop.reload.type_variant(bug)).to eq(bug.default_variant)
          expect(foundry.reload.type_variant(bug)).to eq(hardware)
        end
      end

      context "when the target is another type's variant" do
        let(:target) { create(:type).default_variant }

        it "is refused" do
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(bookshop.reload.type_variant(bug)).to eq(bug.default_variant)
        end
      end

      context "with a project that does not use the type" do
        let(:projects) { [bookshop, foundry, unrelated] }

        it "leaves it alone" do
          expect { subject }.not_to change { unrelated.reload.project_types.pluck(:id) }

          expect(response).to have_http_status(:ok)
          expect(bookshop.reload.type_variant(bug)).to eq(firmware)
        end
      end

      context "when only one of them uses the type" do
        let(:projects) { [bookshop, unrelated] }

        it "switches that one" do
          subject

          expect(response.body).to include("type-variant-switch-confirm-dialog")
            .and include("The project now uses Bug: Firmware.")
          expect(bookshop.reload.type_variant(bug)).to eq(firmware)
        end
      end

      context "when the switch is refused for one project" do
        before do
          refusal = ServiceResult.failure(result: foundry)
          refusal.errors.add(:base, "Refused for a reason")

          allow(Projects::Types::SwitchVariantService).to receive(:new).and_call_original
          allow(Projects::Types::SwitchVariantService)
            .to receive(:new).with(user: anything, model: foundry)
            .and_return(instance_double(Projects::Types::SwitchVariantService, call: refusal))
        end

        it "switches the others and names the refused one" do
          subject

          expect(bookshop.reload.type_variant(bug)).to eq(firmware)
          expect(foundry.reload.type_variant(bug)).to eq(hardware)
          expect(response.body).to include("Foundry: Refused for a reason")
        end
      end
    end
  end
end
