# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Avatars::SettingsService do
  let(:user) { create(:user) }
  let(:principal) { user }
  let(:service) { described_class.new(principal:, user:) }

  before do
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return true
  end

  shared_examples "avatar settings with an image" do
    it "saves the image, source, and background together" do
      file = Rack::Test::UploadedFile.new(File.expand_path("../../fixtures/valid.jpg", __dir__), "image/jpeg")
      result = service.call(attributes: { avatar_type: "image", avatar_color: "#abc" }, file:)

      expect(result).to be_success
      expect(principal.reload.avatar_type).to eq "image"
      expect(principal.avatar_color).to eq "#AABBCC"
      expect(principal.local_avatar_attachment).to be_present
    end

    it "rolls back the source and color when an image is rejected" do
      file = Rack::Test::UploadedFile.new(File.expand_path("../../fixtures/invalid.txt", __dir__), "text/plain")
      result = service.call(attributes: { avatar_type: "image", avatar_color: "#abc" }, file:)

      expect(result).not_to be_success
      expect(result.errors[:base]).to include I18n.t(:wrong_file_format)
      expect(principal.reload.avatar_type).to be_nil
      expect(principal.avatar_color).to be_nil
      expect(principal.local_avatar_attachment).to be_nil
    end
  end

  it_behaves_like "avatar settings with an image"

  context "for a group" do
    let(:user) { create(:admin) }
    let(:principal) { create(:group) }

    it_behaves_like "avatar settings with an image"
  end
end
