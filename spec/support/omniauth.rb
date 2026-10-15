# frozen_string_literal: true

module OmniauthSpecHelpers
  def start_omniauth_developer
    visit signin_path unless omniauth_developer_flow_visible?

    if page.has_css?(".auth-provider-developer", wait: 0)
      click_link_or_button "Omniauth Developer", match: :first
    end

    submit_omniauth_direct_login_form
  end

  def submit_omniauth_direct_login_form
    return unless page.has_css?("#omniauth-direct-login-form", wait: 0)

    click_button I18n.t("account.omniauth_direct_login_continue")
  end

  def omniauth_developer_flow_visible?
    page.has_css?(".auth-provider-developer, #omniauth-direct-login-form", wait: 0) ||
      page.has_field?("first_name", wait: 0)
  end
end

RSpec.configure do |config|
  config.include OmniauthSpecHelpers, type: :feature

  config.before :each, type: :feature do
    OmniAuth.config.mock_auth[:developer] = nil
  end
end
