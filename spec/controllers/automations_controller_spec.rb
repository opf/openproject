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

RSpec.describe AutomationsController, with_ee: %i[automations] do
  let(:admin) { build(:admin) }
  let(:non_admin) { build(:user) }
  let(:action) { build_stubbed(:automation) }
  let(:params) do
    { automation: { name: "blubs",
                       actions: { assigned_to: 1 } } }
  end

  shared_examples_for "requires enterprise token" do
    context "without an enterprise token", with_ee: false do
      before do
        login_as(admin)

        call
      end

      it "redirects to index" do
        expect(response).to redirect_to action: :index
      end
    end
  end

  shared_examples_for "403 for non admins" do
    context "for non admins" do
      before do
        login_as(non_admin)

        call
      end

      it "returns 403" do
        expect(response.response_code)
          .to be 403
      end
    end
  end

  describe "#index" do
    let(:call) { get :index }

    before do
      allow(Automation)
        .to receive(:order_by_position)
        .and_return([action])
    end

    context "for admins" do
      before do
        login_as(admin)

        call
      end

      it "returns 200" do
        expect(response.response_code)
          .to be 200
      end

      it "renders index template" do
        expect(response)
          .to render_template("index")
      end

      it "assigns the automations" do
        expect(assigns(:automations))
          .to contain_exactly(action)
      end
    end

    context "without an enterprise token", with_ee: false do
      before do
        login_as(admin)

        call
      end

      it "renders ok" do
        expect(response.response_code).to be 200
      end
    end

    it_behaves_like "403 for non admins"
  end

  describe "#new" do
    let(:call) { get(:new) }

    context "for admins" do
      before do
        login_as(admin)

        allow(Automation)
          .to receive(:new)
          .and_return(action)

        call
      end

      it "returns 200" do
        expect(response.response_code)
          .to be 200
      end

      it "renders new template" do
        expect(response)
          .to render_template("new")
      end

      it "assigns automation" do
        expect(assigns(:automation))
          .to eql action
      end
    end

    it_behaves_like "403 for non admins"
    it_behaves_like "requires enterprise token"
  end

  describe "#create" do
    let(:call) { post :create, params: }
    let(:current_user) { admin }
    let(:service_success) { true }
    let(:permitted_params) do
      ActionController::Parameters
        .new(params)
        .require(:automation)
        .permit(:name)
        .merge(ActionController::Parameters.new(actions: { assigned_to: "1" }).permit!)
    end
    let!(:service) do
      service = double("create service")

      allow(Automations::CreateService)
        .to receive(:new)
        .with(user: admin)
        .and_return(service)

      allow(service)
        .to receive(:call)
        .with(attributes: permitted_params.to_h.merge(conditions: {}))
        .and_yield(service_result)

      service
    end
    let(:service_result) do
      ServiceResult.new(success: service_success,
                        result: action)
    end

    context "for admins" do
      before do
        login_as(current_user)

        call
      end

      context "on success" do
        it "redirects to index" do
          expect(response)
            .to redirect_to(automations_path)
        end
      end

      context "on failure" do
        let(:service_success) { false }

        it "renders new" do
          expect(response)
            .to render_template(:new)
        end

        it "assigns custom action" do
          expect(assigns[:automation])
            .to eql action
        end
      end
    end

    it_behaves_like "403 for non admins"
    it_behaves_like "requires enterprise token"
  end

  describe "#edit" do
    let(:params) do
      { id: "42" }
    end
    let(:call) do
      get :edit, params:
    end

    before do
      allow(Automation)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context "for admins" do
      before do
        login_as(admin)

        call
      end

      it "returns 200" do
        expect(response.response_code)
          .to be 200
      end

      it "renders edit template" do
        expect(response)
          .to render_template("edit")
      end

      it "assigns automation" do
        expect(assigns(:automation))
          .to eql action
      end
    end

    context "for admins on invalid id" do
      before do
        allow(Automation)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(admin)

        call
      end

      it "returns 404 NOT FOUND" do
        expect(response.response_code)
          .to be 404
      end
    end

    it_behaves_like "403 for non admins"
    it_behaves_like "requires enterprise token"
  end

  describe "#update" do
    let(:call) { patch :update, params: }
    let(:current_user) { admin }
    let(:service_success) { true }
    let(:permitted_params) do
      ActionController::Parameters
        .new(params)
        .require(:automation)
        .permit(:name)
        .merge(ActionController::Parameters.new(actions: { assigned_to: "1" }).permit!)
    end
    let(:params) do
      { automation: { name: "blubs",
                         actions: { assigned_to: 1 } },
        id: "42" }
    end
    let!(:service) do
      service = double("update service")

      allow(Automations::UpdateService)
        .to receive(:new)
        .with(user: admin, action:)
        .and_return(service)

      allow(service)
        .to receive(:call)
        .with(attributes: permitted_params.to_h.merge(conditions: {}))
        .and_yield(service_result)

      service
    end
    let(:service_result) do
      ServiceResult.new(success: service_success,
                        result: action)
    end

    before do
      allow(Automation)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context "for admins" do
      before do
        login_as(current_user)

        call
      end

      context "on success" do
        it "redirects to index" do
          expect(response)
            .to redirect_to(automations_path)
        end
      end

      context "on failure" do
        let(:service_success) { false }

        it "rerenders edit action" do
          expect(response)
            .to render_template(:edit)
        end

        it "assigns the action" do
          expect(assigns[:automation])
            .to eql(action)
        end
      end
    end

    context "for admins on invalid id" do
      before do
        allow(Automation)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(current_user)

        call
      end

      it "returns 404 NOT FOUND" do
        expect(response.response_code)
          .to be 404
      end
    end

    it_behaves_like "403 for non admins"
    it_behaves_like "requires enterprise token"
  end

  describe "#destroy" do
    let(:call) { delete :destroy, params: }
    let(:current_user) { admin }
    let(:params) do
      { id: "42" }
    end

    before do
      allow(Automation)
        .to receive(:find)
        .with(params[:id])
        .and_return(action)
    end

    context "for admins" do
      before do
        expect(action)
          .to receive(:destroy)
          .and_return(true)

        login_as(current_user)

        call
      end

      it "redirects to index" do
        expect(response)
          .to redirect_to(automations_path)
      end
    end

    context "for admins on invalid id" do
      before do
        allow(Automation)
          .to receive(:find)
          .with(params[:id])
          .and_raise(ActiveRecord::RecordNotFound)

        login_as(current_user)

        call
      end

      it "returns 404 NOT FOUND" do
        expect(response.response_code)
          .to be 404
      end
    end

    context "for admins without an enterprise token", with_ee: false do
      before do
        allow(action)
          .to receive(:destroy)
          .and_return(true)

        login_as(admin)

        call
      end

      it "redirects to index" do
        expect(response).to redirect_to action: :index
        expect(action).to have_received(:destroy)
      end
    end

    it_behaves_like "403 for non admins"
  end
end
