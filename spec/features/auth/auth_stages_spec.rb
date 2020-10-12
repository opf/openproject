#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Authentication Stages', type: :feature do
  before do
    @capybara_ignore_elements = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = true

    OpenProject::Authentication::Stage.register :dummy_step, '/login/stage_test'

    allow_any_instance_of(AccountController)
      .to receive(:stage_secret)
      .and_return('success') # usually 'success' would be a random hex string
  end

  after do
    Capybara.ignore_hidden_elements = @capybara_ignore_elements
    OpenProject::Authentication::Stage.deregister :dummy_step
  end

  let(:user_password) { 'bob' * 4 }
  let(:user) do
    FactoryBot.create(
      :user,
      force_password_change: false,
      first_login: false,
      login: 'bob',
      mail: 'bob@example.com',
      firstname: 'Bo',
      lastname: 'B',
      password: user_password,
      password_confirmation: user_password
    )
  end

  def login!
    visit signin_path
    within('#login-form') do
      fill_in('username', with: user.login)
      fill_in('password', with: user_password)
      click_link_or_button I18n.t(:button_login)
    end
  end

  context 'with automatic registration', with_settings: { self_registration: "3" } do
    before do
      OpenProject::Authentication::Stage.register(:activation_step, run_after_activation: true) do
        # while we're at it let's confirm path helpers work here (/login)
        signin_path.sub "login", "activation/stage_test"
      end

      # this shouldn't influence the specs as it is active
      OpenProject::Authentication::Stage.register :inactive, '/foo/bar', active: ->() { false }
    end

    after do
      OpenProject::Authentication::Stage.deregister :activation_step
      OpenProject::Authentication::Stage.deregister :inactive
    end

    it 'redirects to authentication stage after automatic registration and before login' do
      visit signin_path
      click_on "Create a new account"

      within("#new_user") do
        fill_in "user_login", with: "h.wurst"
        fill_in "user_firstname", with: "Hans"
        fill_in "user_lastname", with: "Wurst"
        fill_in "user_mail", with: "h.wurst@openproject.com"
        fill_in "user_password", with: "hansihansi"
        fill_in "user_password_confirmation", with: "hansihansi"
      end

      expect { click_on("Create") }.to raise_error(ActionController::RoutingError, /\/activation\/stage_test/)
      expect(current_path).to eql "/activation/stage_test"

      # after the stage is finished it must redirect to the complete endpoint
      visit "/login/activation_step/success"

      expect(page).to have_text("Welcome, your account has been activated. You are logged in now.")

      visit "/my/account"

      expect(page).to have_text "h.wurst" # just double checking we're really logged in
    end

    it 'redirects to authentication stage after registration via omniauth too' do
      visit signin_path
      click_on "Create a new account"

      within("#new_user") do
        click_on "Omniauth Developer"
      end

      fill_in "first_name", with: "Adam"
      fill_in "last_name", with: "Apfel"
      fill_in "email", with: "a.apfel@openproject.com"

      expect { click_on("Sign In") }.to raise_error(ActionController::RoutingError, /\/activation\/stage_test/)
      expect(current_path).to eql "/activation/stage_test"

      # after the stage is finished it must redirect to the complete endpoint
      visit "/login/activation_step/success"

      expect(page).to have_text("Welcome, your account has been activated. You are logged in now.")

      visit "/my/account"

      expect(page).to have_text "a.apfel" # just double checking we're really logged in
    end
  end

  it 'redirects to registered authentication stage before actual login if succesful' do
    expect { login! }.to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

    expect(current_path).to eql "/login/stage_test"

    # after the stage is finished it must redirect to the complete endpoint
    visit "/login/dummy_step/success"

    expect(current_path).to eql "/my/page" # after which the user will actually be logged in

    visit "/my/account"

    expect(page).to have_text user.login # just checking we're really logged in
  end

  it 'redirects to the login page and shows an error on verification failure' do
    expect { login! }.to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

    expect(current_path).to eql "/login/stage_test"

    # after the stage is finished it can redirect to the failure endpoint if something went wrong
    visit "/login/dummy_step/sucesz"

    expect(current_path).to eql "/login" # after which the user is shown a generic error message
    expect(page).to have_text "Could not verify stage 'dummy_step'"

    visit "/my/account"

    expect(page).not_to have_text user.login # just checking we're really not logged in
  end

  it 'redirects to the login page and shows an error on authentication stage failure' do
    expect { login! }.to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

    expect(current_path).to eql "/login/stage_test"

    # after the stage is finished it can redirect to the failure endpoint if something went wrong
    visit "/login/dummy_step/failure"

    expect(current_path).to eql "/login" # after which the user is shown a generic error message
    expect(page).to have_text "Authentication stage 'dummy_step' failed."

    visit "/my/account"

    expect(page).not_to have_text user.login # just checking we're really not logged in
  end

  it 'redirects to the login page and shows an error on returning to the wrong stage' do
    expect { login! }.to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

    expect(current_path).to eql "/login/stage_test"

    visit "/login/foobar/success" # redirect to wrong stage endpoint

    expect(current_path).to eql "/login" # after which the user is shown an error message
    expect(page)
      .to have_text "Expected to finish authentication stage 'dummy_step', but 'foobar' returned."

    visit "/my/account"

    expect(page).not_to have_text user.login # just checking we're really not logged in
  end

  it 'redirects to the referer if there is one' do
    visit "/projects"

    click_on "Sign in"

    expect do
      within('#login-form') do
        fill_in('username', with: user.login)
        fill_in('password', with: user_password)
        click_link_or_button I18n.t(:button_login)
      end
    end
      .to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

    expect(current_path).to eql "/login/stage_test"

    # after the stage is finished it must redirect to the complete endpoint
    visit "/login/dummy_step/success"

    expect(current_path).to eql "/projects" # after which the user will actually be logged in

    visit "/my/account"

    expect(page).to have_text user.login # just checking we're really logged in
  end

  context "with two stages" do
    before do
      OpenProject::Authentication::Stage.register :two_step do
        # while we're at it let's confirm path helpers work here (/login)
        signin_path.sub "login", "login/stage_test_2"
      end
    end

    after do
      OpenProject::Authentication::Stage.deregister :two_step
    end

    it 'redirects to both registered authentication stages before actual login if succesful' do
      expect { login! }.to raise_error(ActionController::RoutingError, /\/login\/stage_test/)

      expect(current_path).to eql "/login/stage_test"

      expect { visit "/login/dummy_step/success" }
        .to raise_error(ActionController::RoutingError, /\/login\/stage_test_2/)

      # after the stage is finished it must redirect to the complete endpoint
      visit "/login/two_step/success"

      expect(current_path).to eql "/my/page" # after which the user will actually be logged in

      visit "/my/account"

      expect(page).to have_text user.login # just checking we're really logged in
    end
  end
end
