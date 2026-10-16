# frozen_string_literal: true

require_relative "../../spec_helper"
require_relative "../../shared_examples"

RSpec.describe Avatars::MyAvatarController do
  include_context "there are users with and without avatars"
  let(:user) { user_without_avatar }
  let(:enabled) { true }

  before do
    login_as user
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe "#delete" do
    it "returns invalid method for post request" do
      post :destroy
      expect(response).not_to be_successful
      expect(response).to have_http_status :method_not_allowed
    end

    it "calls the service for delete" do
      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(ServiceResult.success(result: "message"))

      delete :destroy
      expect(flash[:notice]).to include "message"
      expect(flash[:error]).not_to be_present
      expect(response.body).to include 'action="reload"'
    end

    it "calls the service for delete" do
      result = ServiceResult.failure
      result.errors.add :base, "error"

      expect_any_instance_of(Avatars::UpdateService)
        .to receive(:destroy)
        .and_return(result)

      delete :destroy
      expect(flash[:notice]).not_to be_present
      expect(flash[:error]).to include "error"
      expect(response.body).to include 'action="reload"'
    end
  end
end
