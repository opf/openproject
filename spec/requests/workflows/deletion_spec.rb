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

RSpec.describe "Workflows deletion", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  let(:replacement) { create(:named_workflow, name: "Replacement flow") }

  before { login_as admin }

  describe "GET deletion_dialog" do
    it "offers a plain confirmation for an unused workflow" do
      workflow = create(:named_workflow, name: "Spare flow")

      get deletion_dialog_workflow_path(workflow), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("workflows.delete.body_not_in_use"))
      expect(response.body).not_to include(I18n.t("workflows.delete.replace_label"))
    end

    it "lists the affected variants and offers a replacement for a used workflow" do
      workflow = create(:named_workflow)
      create(:type, name: "Bug").default_variant.update!(workflow:)
      replacement

      get deletion_dialog_workflow_path(workflow), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("workflows.delete.replace_label"))
      expect(response.body).to include(I18n.t("workflows.delete.confirmation_checkbox_label"))
      expect(response.body).to include("Bug")
      expect(response.body).to include("Replacement flow")
    end

    it "shows an error flash instead of the dialog when a used workflow has no replacement" do
      workflow = create(:named_workflow)
      create(:type, name: "Bug").default_variant.update!(workflow:)
      Workflow.where.not(id: workflow.id).destroy_all

      get deletion_dialog_workflow_path(workflow), as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(I18n.t("workflows.delete.no_replacement"))
      expect(response.body).not_to include(I18n.t("workflows.delete.replace_label"))
    end
  end

  describe "DELETE destroy" do
    it "deletes an unused workflow" do
      workflow = create(:named_workflow, name: "Spare flow")

      expect { delete workflow_path(workflow), as: :turbo_stream }
        .to change { Workflow.exists?(workflow.id) }.from(true).to(false)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(workflows_path)
    end

    context "when the workflow is in use" do
      let(:workflow) { create(:named_workflow) }
      let!(:variant) { create(:type, name: "Bug").default_variant.tap { it.update!(workflow:) } }

      it "repoints the variants to the replacement and deletes the workflow" do
        replacement

        delete workflow_path(workflow), params: { target_id: replacement.id }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(Workflow.exists?(workflow.id)).to be(false)
        expect(variant.reload.workflow).to eq(replacement)
      end

      it "refuses without a replacement, keeping the workflow" do
        delete workflow_path(workflow), as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Workflow.exists?(workflow.id)).to be(true)
        expect(variant.reload.workflow).to eq(workflow)
      end
    end
  end

  describe "authorization" do
    it "denies non-admins the dialog" do
      login_as create(:user)
      workflow = create(:named_workflow)

      get deletion_dialog_workflow_path(workflow), as: :turbo_stream

      expect(response).not_to have_http_status(:ok)
    end

    it "denies non-admins the deletion" do
      login_as create(:user)
      workflow = create(:named_workflow)

      delete workflow_path(workflow), as: :turbo_stream

      expect(response).not_to have_http_status(:see_other)
      expect(Workflow.exists?(workflow.id)).to be(true)
    end
  end
end
