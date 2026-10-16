# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Avatars::GroupsController do
  let(:current_user) { create(:admin) }
  let(:enabled) { true }
  let(:group) { create(:group) }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return enabled
  end

  describe "#update" do
    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "renders 403" do
        post :update, params: { id: group.id }
        expect(response).to redirect_to signin_path(back_url: edit_group_avatar_url(group))
      end
    end

    context "as a non-admin" do
      let(:current_user) { create(:user) }

      it "renders 403" do
        put :update, params: { id: group.id }
        expect(response).to have_http_status :forbidden
      end
    end

    context "when not enabled" do
      let(:enabled) { false }

      it "renders 404" do
        put :update, params: { id: group.id }
        expect(response).to have_http_status :not_found
      end
    end

    it "returns invalid method for post request" do
      post :update, params: { id: group.id }
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for put" do
      service = instance_double(Avatars::UpdateService)
      allow(Avatars::UpdateService).to receive(:new).and_return(service)
      allow(service).to receive(:replace).and_return(ServiceResult.success(result: "Avatar changed successfully."))

      put :update, params: { id: group.id }
      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(flash[:notice]).to eq("Avatar changed successfully.")
    end
  end

  describe "#destroy" do
    it "calls the service for delete" do
      service = instance_double(Avatars::UpdateService)
      allow(Avatars::UpdateService).to receive(:new).and_return(service)
      allow(service).to receive(:destroy).and_return(ServiceResult.success(result: "message"))

      delete :destroy, params: { id: group.id }
      expect(flash[:notice]).to include "message"
      expect(response.body).to include 'action="reload"'
    end
  end

  describe "#update_color" do
    it "updates the group's avatar color" do
      patch :update_color, params: { id: group.id, avatar_color: "#abc" }

      expect(flash[:notice]).to eq I18n.t("avatars.message_avatar_color_updated")
      expect(group.reload.avatar_color).to eq "#AABBCC"
    end

    it "rejects an invalid color" do
      patch :update_color, params: { id: group.id, avatar_color: "not-a-color" }

      expect(flash[:error]).to be_present
      expect(group.reload.avatar_color).to be_nil
    end
  end
end
