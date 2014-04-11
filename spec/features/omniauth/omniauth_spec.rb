require 'spec_helper'

describe 'Omniauth authentication' do
  after do
    User.delete_all
    User.current = nil
    OmniAuth.config.test_mode = false
    Capybara.ignore_hidden_elements = true
  end

  it 'should sign in existing user' do
    FactoryGirl.create(:user, force_password_change: false, identity_url: 'developer:foo@bar.com', login: 'bob', mail: 'foo@bar.com')
    Capybara.ignore_hidden_elements = false

    visit '/auth/developer'
    fill_in('name', with: 'bob')
    fill_in('email', with: 'foo@bar.com')
    click_link_or_button 'Sign In'
    expect(page).to have_link('Sign out')
  end

  it 'should fail with generic error message' do
    # set omniauth to test mode will redirect all calls to omniauth
    # directly to the callback and by setting the mock_auth provider
    # to a symbol will force omniauth to fail /auth/failure
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = :invalid_credentials
    visit '/auth/developer'
    expect(page).to have_content(I18n.t(:error_external_authentication_failed))
  end
end
