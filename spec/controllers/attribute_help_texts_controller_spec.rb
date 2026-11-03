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

RSpec.describe AttributeHelpTextsController do
  let(:user) { build_stubbed(:user) }
  let!(:model) { create(:work_package_help_text) }

  before do
    login_as user

    mock_permissions_for(user) do |mock|
      mock.allow_globally :edit_attribute_help_texts
    end
  end

  describe "#index" do
    before do
      get :index
    end

    it "is successful" do
      expect(response).to be_successful
      expect(assigns(:attribute_help_texts).count).to eq(1)
    end
  end

  describe "#show_dialog" do
    let(:visible_scope) { instance_double(ActiveRecord::Relation) }

    before do
      allow(AttributeHelpText)
        .to receive(:visible)
        .with(user)
        .and_return(visible_scope)

      allow(visible_scope)
        .to receive(:find)
        .and_raise ActiveRecord::RecordNotFound

      allow(visible_scope)
        .to receive(:find)
        .with(model.id.to_s)
        .and_return(model)

      get :show_dialog, params: { id: find_id }, format: :turbo_stream
    end

    context "when found" do
      let(:find_id) { model.id }

      it "renders turbo stream dialog action", :aggregate_failures do
        expect(response).to be_successful
        expect(assigns(:attribute_help_text)).to eq model
        expect(response).to have_turbo_stream action: "dialog", target: "attribute-help-texts-show-dialog-component"
      end
    end

    context "when not found" do
      let(:find_id) { "123451234" }

      it "responds with 404 Not Found status", :aggregate_failures do
        expect(response).not_to be_successful
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#edit" do
    before do
      get :edit, params: { id: find_id }
    end

    context "when found" do
      let(:find_id) { model.id }

      it "is successful" do
        expect(response).to be_successful
        expect(assigns(:attribute_help_text)).to eql model
      end
    end

    context "when not found" do
      let(:find_id) { "123451234" }

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#update" do
    let(:find_id) { model.id.to_s }
    let(:call) do
      put :update,
          params: {
            id: find_id,
            attribute_help_text: {
              help_text: "my new help text"
            }
          }
    end

    context "when save is success" do
      before do
        allow(AttributeHelpText).to receive(:find).with(find_id).and_return(model)
        allow(model).to receive(:save).and_return(true)

        call
      end

      it "edits the announcement" do
        expect(response).to redirect_to action: :index, tab: "WorkPackage"
        expect(controller).to set_flash[:notice].to I18n.t(:notice_successful_update)

        expect(model.help_text).to eq("my new help text")
      end
    end

    context "when save is failure" do
      before do
        allow(AttributeHelpText).to receive(:find).with(find_id).and_return(model)
        allow(model).to receive(:save).and_return(false)

        call
      end

      it "fails to update the announcement" do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template "edit"
      end
    end

    context "when not found" do
      let(:find_id) { "123451234" }

      before do
        call
      end

      it "returns 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end
end
