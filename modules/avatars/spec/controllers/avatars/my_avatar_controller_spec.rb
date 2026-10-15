# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Avatars::MyAvatarController do
  let(:current_user) { create(:user) }
  let(:enabled) { true }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(OpenProject::Avatars::AvatarManager).to receive(:local_avatars_enabled?).and_return enabled
  end

  describe "#show" do
    it "renders the dedicated account page" do
      get :show

      expect(response).to be_successful
      expect(response).to render_template :show
    end

    context "when Gravatar and local avatars are disabled" do
      let(:enabled) { false }

      before do
        allow(OpenProject::Avatars::AvatarManager).to receive(:gravatar_enabled?).and_return false
      end

      it "still renders the page" do
        get :show

        expect(response).to be_successful
        expect(response).to render_template :show
      end
    end
  end

  describe "#update_settings" do
    it "saves the selected source, characters, and color together" do
      patch :update_settings, params: { avatar_type: "initials", avatar_text: "👩🏽‍💻", avatar_color: "#abc" }

      expect(response).to redirect_to edit_my_avatar_path
      expect(current_user.reload.avatar_type).to eq "initials"
      expect(current_user.avatar_text).to eq "👩🏽‍💻"
      expect(current_user.avatar_color).to eq "#AABBCC"
    end

    it "rejects more than two emoji without saving the color" do
      patch :update_settings, params: { avatar_type: "initials", avatar_text: "🚀🚀🚀", avatar_color: "#abc" }

      expect(flash[:error]).to be_present
      expect(current_user.reload.avatar_type).to be_nil
      expect(current_user.avatar_color).to be_nil
    end

    it "uses default initials without an override" do
      current_user.pref.update!(settings: { avatar_type: "initials", avatar_text: "OP" })
      patch :update_settings, params: { avatar_type: "initials", avatar_text: " " }

      expect(flash[:notice]).to be_present
      expect(current_user.reload.avatar_type).to eq "initials"
      expect(current_user.avatar_text).to be_nil
    end

    it "rejects a source disabled by the administrator" do
      allow(OpenProject::Avatars::AvatarManager).to receive(:gravatar_enabled?).and_return false

      patch :update_settings, params: { avatar_type: "gravatar" }

      expect(flash[:error]).to be_present
      expect(current_user.reload.avatar_type).to be_nil
    end

    context "when Gravatar and local avatars are disabled" do
      let(:enabled) { false }

      before do
        allow(OpenProject::Avatars::AvatarManager).to receive(:gravatar_enabled?).and_return false
      end

      it "saves custom text and background color" do
        patch :update_settings, params: { avatar_type: "initials", avatar_text: "🚀", avatar_color: "#abc" }

        expect(flash[:notice]).to be_present
        expect(current_user.reload.avatar_type).to eq "initials"
        expect(current_user.avatar_text).to eq "🚀"
        expect(current_user.avatar_color).to eq "#AABBCC"
      end

      it "rejects the disabled image option" do
        patch :update_settings, params: { avatar_type: "image" }

        expect(flash[:error]).to be_present
        expect(current_user.reload.avatar_type).to be_nil
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "requires login" do
        patch :update_settings, params: { avatar_type: "initials" }

        expect(response).to have_http_status :redirect
      end
    end
  end

  describe "#update_text" do
    it "updates and trims custom text while preserving other preferences" do
      current_user.pref.update!(settings: { avatar_color: "#AABBCC", comments_sorting: "asc" })

      patch :update_text, params: { avatar_text: " 👩🏽‍💻 " }

      expect(flash[:notice]).to eq I18n.t("avatars.message_avatar_text_updated")
      expect(current_user.reload.avatar_text).to eq "👩🏽‍💻"
      expect(current_user.avatar_color).to eq "#AABBCC"
      expect(current_user.pref.comments_sorting).to eq "asc"
      expect(response.body).to include 'action="reload"'
    end

    it "clears custom text" do
      current_user.pref.update!(settings: { avatar_text: "OP" })

      patch :update_text, params: { avatar_text: " " }

      expect(flash[:notice]).to be_present
      expect(current_user.reload.avatar_text).to be_nil
    end

    it "preserves stored text when rejecting more than two characters" do
      current_user.pref.update!(settings: { avatar_text: "OP" })

      patch :update_text, params: { avatar_text: "ABC" }

      expect(flash[:error]).to be_present
      expect(current_user.reload.avatar_text).to eq "OP"
    end

    it "ignores attributes other than avatar text" do
      patch :update_text, params: { avatar_text: "🚀", avatar_color: "#AABBCC", admin: true }

      expect(current_user.reload.avatar_text).to eq "🚀"
      expect(current_user.avatar_color).to be_nil
      expect(current_user).not_to be_admin
    end

    context "when local avatars are disabled" do
      let(:enabled) { false }

      it "still updates the text" do
        patch :update_text, params: { avatar_text: "OP" }

        expect(response).to have_http_status :ok
        expect(current_user.reload.avatar_text).to eq "OP"
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "redirects to login" do
        patch :update_text, params: { avatar_text: "OP" }

        expect(response).to redirect_to signin_path(back_url: update_text_edit_my_avatar_url)
      end
    end
  end
end
