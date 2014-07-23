require 'spec_helper'

describe 'Omniauth authentication' do

  before do
    @omniauth_test_mode = OmniAuth.config.test_mode
    @capybara_ignore_elements = Capybara.ignore_hidden_elements
    @omniauth_logger = OmniAuth.config.logger
    OmniAuth.config.logger = Rails.logger
    Capybara.ignore_hidden_elements = false
  end

  after do
    User.delete_all
    User.current = nil
    OmniAuth.config.test_mode = @omniauth_test_mode
    Capybara.ignore_hidden_elements = @capybara_ignore_elements
    OmniAuth.config.logger = @omniauth_logger
  end

  context 'sign in existing user' do
    let(:user) do
      FactoryGirl.create(:user,
                         force_password_change: false,
                         identity_url: 'developer:omnibob@example.com',
                         login: 'omnibob',
                         mail: 'omnibob@example.com',
                         firstname: 'omni',
                         lastname: 'bob'
                        )
    end

    it 'should redirect to back url' do
      visit account_lost_password_path
      find_link('Omniauth Developer').click
      fill_in('first_name', with: user.firstname)
      fill_in('last_name', with: user.lastname)
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      expect(current_url).to eql account_lost_password_url
    end

    it 'should sign in user' do
      visit '/auth/developer'
      fill_in('first_name', with: user.firstname)
      fill_in('last_name', with: user.lastname)
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      expect(page).to have_content('omni bob')
      expect(page).to have_link('Sign out')
    end
  end

  shared_examples 'omniauth user registration' do
    it 'should register new user' do
      visit '/auth/developer'

      # login form developer strategy
      fill_in('first_name', with: user.firstname)
      # intentionally do not supply last_name
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      # on register form, we are prompted for a last name
      fill_in('user_lastname', with: user.lastname)
      click_link_or_button 'Submit'

      expect(page).to have_content(I18n.t(:notice_account_registered_and_logged_in))
      expect(page).to have_link('Sign out')
    end
  end

  context 'register on the fly' do
    let(:user) do
      User.new(force_password_change: false,
               identity_url: 'developer:omnibob@example.com',
               login: 'omnibob',
               mail: 'omnibob@example.com',
               firstname: 'omni',
               lastname: 'bob')
    end

    before do
      allow(Setting).to receive(:self_registration?).and_return(true)
      allow(Setting).to receive(:self_registration).and_return('3')
    end

    it_behaves_like 'omniauth user registration'

    it 'should redirect to back url' do
      visit account_lost_password_path
      find_link('Omniauth Developer').click

      # login form developer strategy
      fill_in('first_name', with: user.firstname)
      # intentionally do not supply last_name
      fill_in('email', with: user.mail)
      click_link_or_button 'Sign In'

      # on register form, we are prompted for a last name
      fill_in('user_lastname', with: user.lastname)
      click_link_or_button 'Submit'

      # now, we see the my/first_login page and just save
      click_link_or_button 'Save'

      expect(current_url).to eql account_lost_password_url
    end

    context 'with password login disabled' do
      before do
        OpenProject::Configuration.stub(:disable_password_login?).and_return(true)
      end

      it_behaves_like 'omniauth user registration'
    end
  end

  context 'error occurs' do
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
end
