# frozen_string_literal: true

module OmniauthSpecHelpers
  def start_omniauth_developer
    visit signin_path unless page.has_css?(".auth-provider-developer, #omniauth-direct-login-form") ||
      page.has_field?("first_name")

    if page.has_button?(I18n.t("account.omniauth_direct_login_continue"))
      click_button I18n.t("account.omniauth_direct_login_continue")
    elsif page.has_button?("Omniauth Developer") || page.has_link?("Omniauth Developer")
      click_link_or_button "Omniauth Developer", match: :first
    end
  end
end

RSpec.configure do |config|
  config.include OmniauthSpecHelpers, type: :feature

  config.before :each, type: :feature do
    OmniAuth.config.mock_auth[:developer] = nil
  end
end
