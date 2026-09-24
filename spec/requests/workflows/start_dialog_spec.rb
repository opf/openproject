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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Choosing where a new workflow starts", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:role) { create(:project_role) }
  shared_let(:status_a) { create(:status) }
  shared_let(:status_b) { create(:status) }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:source) { create(:named_workflow, name: "Standard flow") }

  before_all do
    create(:workflow, workflow: source, role:, old_status: status_a, new_status: status_b)
  end

  before { login_as admin }

  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:step_url) { type_creation_wizard_path(type_id: type.id, step: :workflows) }

  def streamed = Capybara.string(response.body[%r{<template>(.*)</template>}m, 1].to_s)

  def transitions_of(workflow) = workflow.status_transitions.pluck(:old_status_id, :new_status_id)

  describe "the starting point dialog" do
    it "offers a copy and a blank start, with the source to copy from" do
      get start_dialog_type_workflow_path(type_id: type.id, back_url: step_url), headers: turbo

      expect(response).to have_http_status(:ok)
      expect(streamed).to have_css("[data-test-selector='workflow-start-copy']", visible: :all)
      expect(streamed).to have_css("[data-test-selector='workflow-start-scratch']", visible: :all)
      expect(streamed).to have_css("[data-test-selector='workflow-copy-source']", visible: :all)
    end

    it "submits to the wizard's own action, which names the workflow later" do
      get start_dialog_type_workflow_path(type_id: type.id, back_url: step_url), headers: turbo

      expect(streamed).to have_css("form[action^='#{start_type_workflow_path(type_id: type.id)}']", visible: :all)
    end

    it "submits to the naming step everywhere else" do
      get configure_dialog_type_workflow_path(type_id: type.id), headers: turbo

      expect(streamed).to have_css("form[action^='#{configure_type_workflow_path(type_id: type.id)}']", visible: :all)
    end
  end

  describe "starting from the wizard" do
    subject(:assigned) { type.default_variant.reload.workflow }

    def start(params)
      post start_type_workflow_path(type_id: type.id, back_url: step_url), params:, headers: turbo
    end

    it "names the workflow after the type and returns to the step" do
      expect { start(start: "scratch") }.to change(Workflow, :count).by(1)

      expect(response).to redirect_to(step_url)
      expect(assigned.name).to eq("Bug workflow (2)")
      expect(transitions_of(assigned)).to be_empty
    end

    it "copies the transitions of the workflow it was told to start from" do
      start(start: "copy", copy_from_id: source.id)

      expect(transitions_of(assigned)).to contain_exactly([status_a.id, status_b.id])
    end

    it "keeps the source out of it when starting from scratch" do
      start(start: "scratch", copy_from_id: source.id)

      expect(transitions_of(assigned)).to be_empty
    end

    it "asks again rather than creating anything when the source is missing" do
      original = assigned

      expect { start(start: "copy") }.not_to change(Workflow, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(streamed).to have_text(I18n.t("workflows.start.copy.missing"))
      expect(type.default_variant.reload.workflow).to eq(original)
    end
  end

  describe "starting from a tab or the index" do
    it "carries the chosen source into the dialog that names the workflow" do
      post configure_type_workflow_path(type_id: type.id),
           params: { start: "copy", copy_from_id: source.id }, headers: turbo

      expect(streamed).to have_css("input[name='workflow[copy_from_id]'][value='#{source.id}']", visible: :all)
      expect(streamed).to have_no_css("[data-test-selector='workflow-copy-from']", visible: :all)
    end

    it "carries no source when starting from scratch, and still does not ask for one" do
      post configure_type_workflow_path(type_id: type.id), params: { start: "scratch" }, headers: turbo

      expect(streamed).to have_no_field("workflow[copy_from_id]", type: :hidden)
      expect(streamed).to have_no_css("[data-test-selector='workflow-copy-from']",
                                      visible: :all)
    end

    it "offers the same pair on the workflows index, where no variant is involved" do
      get configure_dialog_workflows_path, headers: turbo
      expect(streamed).to have_css("[data-test-selector='workflow-start-copy']", visible: :all)

      post configure_workflows_path, params: { start: "copy", copy_from_id: source.id }, headers: turbo

      expect(streamed).to have_css("input[name='workflow[copy_from_id]'][value='#{source.id}']", visible: :all)
    end
  end
end
