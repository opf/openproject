# frozen_string_literal: true

require "spec_helper"

require "services/base_services/behaves_like_create_service"

RSpec.describe RemoteIdentities::CreateService, type: :model do
  let(:user) { create(:user) }
  let(:storage) { create(:nextcloud_storage_configured) }
  let(:oauth_config) { storage.oauth_configuration }
  let(:oauth_token) { Rack::OAuth2::AccessToken.new(access_token: "sudo-access-token", user_id: "bob-from-accounting") }

  subject(:service) { described_class.new(user:, oauth_config:, oauth_token:) }

  describe ".call" do
    it "requires a user, a oauth configuration and a rack token" do
      method = described_class.method :call

      expect(method.parameters).to contain_exactly(%i[keyreq user], %i[keyreq oauth_config], %i[keyreq oauth_token])
    end

    it "succeeds" do
      expect(described_class.call(user:, oauth_config:, oauth_token:)).to be_success
    end
  end

  describe "#user" do
    it "exposes a user which is available as a getter" do
      expect(service.user).to eq(user)
    end
  end

  describe "#call" do
    it "succeeds" do
      expect(service.call).to be_success
    end

    it "returns the model as a result" do
      result = service.call.result
      expect(result).to be_a RemoteIdentity
    end

    context "if creation fails" do
      let(:oauth_token) { Rack::OAuth2::AccessToken.new(access_token: "sudo-access-token") }

      it "is unsuccessful" do
        expect(service.call).to be_failure
      end

      it "exposes the errors" do
        result = service.call
        expect(result.errors.size).to eq(1)
        expect(result.errors[:origin_user_id]).to eq(["can't be blank."])
      end
    end
  end
end
