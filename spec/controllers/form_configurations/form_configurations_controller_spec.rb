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

RSpec.describe FormConfigurations::FormConfigurationsController do
  let(:form) { create(:type).default_variant.form_configuration }
  let(:user) { create(:admin) }

  before do
    allow(User).to receive(:current).and_return(user)
    form.update!(attribute_groups: [["People", %w[assignee]]])
  end

  describe "PATCH #reset" do
    it "puts the form back on the defaults and returns to its page" do
      patch :reset, params: { id: form.id }

      expect(response).to redirect_to(edit_form_configuration_path(form))
      expect(form.reload.form_groups.map(&:default_key)).to include("people", "details")
    end

    it "takes the form's layout lock" do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

      patch :reset, params: { id: form.id }

      expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(form, "layout")
    end

    context "when the form is deleted while the layout lock is held" do
      before do
        allow(OpenProject.logger).to receive(:error)
        allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_raise(ActiveRecord::RecordNotFound)
      end

      it "is reported as a missing record" do
        patch :reset, params: { id: form.id }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an account that is not an administrator" do
      let(:user) { create(:user) }

      it "is refused" do
        patch :reset, params: { id: form.id }

        expect(response).to have_http_status(:forbidden)
        expect(form.reload.form_groups.map(&:label)).to eq(["People"])
      end
    end
  end

  describe "GET #edit for a form created from scratch" do
    render_views

    let(:scratch) { create(:form_configuration) }

    it "persists and shows the default groups instead of the blankslate", :aggregate_failures do
      get :edit, params: { id: scratch.id }

      expect(response).to have_http_status(:ok)
      expect(scratch.form_groups.reload).not_to be_empty
      expect(response.body).to include(I18n.t(:label_details))
    end
  end

  describe "GET #edit for the form of a fresh milestone type" do
    let(:variant) { create(:type_milestone).default_variant }

    it "leaves the milestone's effective groups unchanged" do
      before = variant.attribute_groups.map(&:key)

      get :edit, params: { id: variant.form_configuration.id }

      expect(variant.reload.attribute_groups.map(&:key)).to eq(before)
    end
  end

  describe "GET #configure_dialog" do
    it "opens the start dialog for an administrator" do
      get :configure_dialog, format: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    context "with an account that is not an administrator" do
      let(:user) { create(:user) }

      it "is refused" do
        get :configure_dialog, format: :turbo_stream

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #configure" do
    it "moves on to naming when starting from scratch" do
      post :configure, params: { start: "scratch" }, format: :turbo_stream

      expect(response).to have_http_status(:ok)
    end

    it "keeps asking when copy is chosen without a source" do
      post :configure, params: { start: "copy" }, format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST #create" do
    it "creates a form from scratch and lands on its page", :aggregate_failures do
      expect { post :create, params: { form_configuration: { name: "Release form" } }, format: :turbo_stream }
        .to change(FormConfiguration, :count).by(1)

      expect(response).to redirect_to(edit_form_configuration_path(FormConfiguration.find_by(name: "Release form")))
    end

    it "copies the attribute groups of the form it starts from" do
      source = create(:form_configuration).tap do |form|
        form.update!(attribute_groups: [["People", %w[assignee]]])
      end

      post :create, params: { form_configuration: { name: "Copied form", copy_from_id: source.id } }, format: :turbo_stream

      expect(FormConfiguration.find_by(name: "Copied form").attribute_groups.map(&:key)).to eq(%w[People])
    end

    it "refuses a name another form already has", :aggregate_failures do
      create(:form_configuration, name: "Taken")

      expect { post :create, params: { form_configuration: { name: "Taken" } }, format: :turbo_stream }
        .not_to change(FormConfiguration, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "with an account that is not an administrator" do
      let(:user) { create(:user) }

      it "is refused", :aggregate_failures do
        expect { post :create, params: { form_configuration: { name: "Release form" } }, format: :turbo_stream }
          .not_to change(FormConfiguration, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
