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

RSpec.describe "Forms and workflows started in the creation wizard", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }

  before { login_as admin }

  let(:variant) { type.default_variant }
  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html" } }

  def page = Capybara.string(response.body)

  def step_url(step, **) = type_creation_wizard_path(type_id: type.id, step:, **)

  def streamed_page = Capybara.string(response.body[%r{<template>(.*)</template>}m, 1].to_s)

  shared_examples "a started reference kept out of the existing ones" do
    let!(:other) { create(factory, name: "Standard choice") }
    let(:started) { create(factory, name: "Started choice") }
    let(:started_step_url) { step_url(step, started_key => started.id) }
    let(:wizard_params) { { type_id: type.id, back_url: step_url(step), started_key => started.id } }

    def assign(record) = variant.update!(foreign_key => record.id)

    it "leaves it out of the change dialog" do
      assign(started)

      get public_send(:"change_dialog_type_#{route_key}_path", **wizard_params), headers: turbo

      expect(response.body).to include("Standard choice")
      expect(response.body).not_to include("Started choice")
    end

    it "offers every one outside the wizard" do
      assign(started)

      get public_send(:"change_dialog_type_#{route_key}_path", type_id: type.id), headers: turbo

      expect(response.body).to include("Started choice")
    end

    it "leaves an abandoned one out of the existing card" do
      started
      assign(other)

      get started_step_url

      selector = page.find("[data-test-selector='#{route_key}-panel']", visible: :all)
      expect(selector).to have_text(:all, "Standard choice")
      expect(selector).to have_no_text(:all, "Started choice")
    end
  end

  shared_examples "a started reference discarded when starting again" do
    let!(:other) { create(factory, name: "Standard choice") }
    let!(:previous) { create(factory, name: "Previous choice") }

    def assign(record, to: variant) = to.update!(foreign_key => record.id)

    def wizard_params(previous_id = previous.id) = { type_id: type.id, back_url: step_url(step), started_key => previous_id }

    def start_again(previous_id = previous.id, **params)
      post public_send(:"start_type_#{route_key}_path", **wizard_params(previous_id)),
           params: { start: "scratch", confirmed: "true", **params }
    end

    def started_now = variant.reload.public_send(foreign_key.to_s.delete_suffix("_id"))

    it "carries it on to the address the start dialog submits to" do
      get public_send(:"start_dialog_type_#{route_key}_path", **wizard_params), headers: turbo

      expect(streamed_page).to have_css("form[action*='#{started_key}=#{previous.id}']")
    end

    it "deletes the one abandoned before" do
      assign(other)

      expect { start_again }.not_to change(model_class, :count)

      expect(model_class).not_to exist(previous.id)
      expect(response).to redirect_to(/#{started_key}=#{variant.reload[foreign_key]}/)
    end

    it "hands the name of the one abandoned before to the next" do
      previous.update!(name: model_class.implicit_name(variant.composite_name))
      assign(other)

      start_again

      expect(started_now.name).to eq(previous.name)
    end

    it "copies the one abandoned before, then deletes it" do
      assign(other)

      start_again(start: "copy", copy_from_id: previous.id)

      expect(started_now).not_to eq(other)
      expect(model_class).not_to exist(previous.id)
    end

    it "deletes the one it replaces" do
      assign(previous)

      expect { start_again }.not_to change(model_class, :count)

      expect(model_class).not_to exist(previous.id)
    end

    it "never deletes one another variant uses" do
      assign(other)
      assign(previous, to: create(:type, name: "Feature").default_variant)

      expect { start_again }.to change(model_class, :count).by(1)

      expect(model_class).to exist(previous.id)
    end

    it "ignores one already gone" do
      assign(other)
      gone_id = previous.id
      previous.destroy!

      expect { start_again(gone_id) }.to change(model_class, :count).by(1)

      expect(response).to redirect_to(/#{started_key}=#{variant.reload[foreign_key]}/)
    end
  end

  describe "choosing an existing form" do
    it_behaves_like "a started reference kept out of the existing ones" do
      let(:factory) { :form_configuration }
      let(:route_key) { "form_configuration" }
      let(:step) { :form_configuration }
      let(:foreign_key) { :form_configuration_id }
      let(:started_key) { :started_form_configuration_id }
    end
  end

  describe "starting a form again" do
    it_behaves_like "a started reference discarded when starting again" do
      let(:model_class) { FormConfiguration }
      let(:factory) { :form_configuration }
      let(:route_key) { "form_configuration" }
      let(:step) { :form_configuration }
      let(:foreign_key) { :form_configuration_id }
      let(:started_key) { :started_form_configuration_id }
    end
  end

  describe "choosing an existing workflow" do
    it_behaves_like "a started reference kept out of the existing ones" do
      let(:factory) { :named_workflow }
      let(:route_key) { "workflow" }
      let(:step) { :workflows }
      let(:foreign_key) { :workflow_id }
      let(:started_key) { :started_workflow_id }
    end
  end

  describe "starting a workflow again" do
    it_behaves_like "a started reference discarded when starting again" do
      let(:model_class) { Workflow }
      let(:factory) { :named_workflow }
      let(:route_key) { "workflow" }
      let(:step) { :workflows }
      let(:foreign_key) { :workflow_id }
      let(:started_key) { :started_workflow_id }
    end
  end

  describe "carrying the started workflow" do
    before { get type_creation_wizard_path(type_id: type.id, step: :workflows, started_workflow_id: 42) }

    it "keeps it on the address the step submits to" do
      expect(page).to have_css("form#type-wizard-form[action*='started_workflow_id=42']")
    end

    it "hands it to both dialogs" do
      %w[existing new].each do |choice|
        expect(page).to have_css("[data-test-selector='workflow-choice-#{choice}'][data-dialog-url*='&started_workflow_id=42']",
                                 visible: :all)
      end
    end
  end
end
