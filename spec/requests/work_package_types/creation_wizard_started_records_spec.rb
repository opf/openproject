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

  describe "choosing an existing form" do
    it_behaves_like "a started reference kept out of the existing ones" do
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
