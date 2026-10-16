# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Avatars::GroupsController do
  let(:current_user) { create(:admin) }
  let(:enabled) { true }
  let(:group) { create(:group) }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe "#update_settings" do
    it "updates the group's avatar and returns to the avatar tab" do
      patch :update_settings, params: { id: group.id, avatar_type: "initials", avatar_text: "🚀", avatar_color: "#123456" }

      expect(response).to redirect_to edit_group_path(group, tab: :avatar)
      expect(group.reload.avatar_type).to eq "initials"
      expect(group.avatar_text).to eq "🚀"
      expect(group.avatar_color).to eq "#123456"
    end

    it "never allows Gravatar for a group" do
      patch :update_settings, params: { id: group.id, avatar_type: "gravatar" }

      expect(flash[:error]).to be_present
      expect(group.reload.avatar_type).to be_nil
    end

    context "as a non-admin" do
      let(:current_user) { create(:user) }

      it "forbids changing the settings" do
        patch :update_settings, params: { id: group.id, avatar_type: "initials" }

        expect(response).to have_http_status :forbidden
        expect(group.reload.avatar_type).to be_nil
      end
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
end
