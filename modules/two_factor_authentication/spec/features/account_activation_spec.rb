require_relative "../spec_helper"
require_relative "shared_2fa_examples"

RSpec.describe "activating an invited account", :js,
               with_settings: {
                 plugin_openproject_two_factor_authentication: { "active_strategies" => [:developer] }
               } do
  let(:user) do
    user = build(:user, first_login: true)
    UserInvitation.invite_user! user

    user
  end
  let(:token) { Token::Invitation.find_by(user_id: user.id) }

  def activate!
    visit url_for(controller: :account,
                  action: :activate,
                  token: token.value,
                  only_path: true)

    expect(page).to have_current_path account_register_path

    fill_in I18n.t("attributes.password"), with: "Password1234"
    fill_in I18n.t("activerecord.attributes.user.password_confirmation"), with: "Password1234"

    click_button I18n.t(:button_create)
  end

  context "when not enforced and no device present" do
    it "redirects to active" do
      activate!

      visit my_account_path
      expect(page).to have_css(".form--field-container", text: user.login)
    end
  end

  context "when not enforced, but device present" do
    let!(:device) { create(:two_factor_authentication_device_sms, user:, default: true) }

    it "requests a OTP" do
      sms_token = nil
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(OpenProject::TwoFactorAuthentication::TokenStrategy::Developer)
          .to receive(:create_mobile_otp).and_wrap_original do |m|
        sms_token = m.call
      end
      # rubocop:enable RSpec/AnyInstance

      activate!

      expect_flash(message: "Developer strategy generated the following one-time password:")

      SeleniumHubWaiter.wait
      fill_in I18n.t(:field_otp), with: sms_token
      click_button I18n.t(:button_login)

      visit my_account_path
      expect(page).to have_css(".form--field-container", text: user.login)
    end

    it "handles faulty user input on two factor authentication" do
      activate!

      expect_flash(message: "Developer strategy generated the following one-time password:")

      fill_in I18n.t(:field_otp), with: "asdf" # faulty token
      click_button I18n.t(:button_login)

      expect(page).to have_current_path signin_path
      expect(page).to have_content(I18n.t(:notice_account_otp_invalid))
    end
  end

  context "when enforced",
          with_settings: {
            plugin_openproject_two_factor_authentication: {
              "active_strategies" => [:developer],
              "enforced" => true
            }
          } do
    before do
      activate!
    end

    it_behaves_like "create enforced sms device"
  end
end
