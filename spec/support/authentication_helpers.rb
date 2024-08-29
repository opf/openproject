#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "rack_session_access/capybara"

module AuthenticationHelpers
  def self.included(base)
    base.extend(ClassMethods)
  end

  def login_as(user)
    if is_a?(RSpec::Rails::FeatureExampleGroup)
      # If we want to mock having finished the login process
      # we must set the user_id in rack.session accordingly
      # Otherwise e.g. calls to Warden will behave unexpectantly
      # as they will login AnonymousUser
      if using_cuprite? && js_enabled?
        page.driver.set_cookie(
          OpenProject::Configuration["session_cookie_name"],
          session_value_for(user).to_s
        )
      else
        page.set_rack_session(session_value_for(user))
      end
    end

    allow(RequestStore).to receive(:[]).and_call_original
    allow(RequestStore).to receive(:[]).with(:current_user).and_return(user)
  end

  def login_with(login, password, autologin: false, visit_signin_path: true)
    visit signin_path if visit_signin_path

    within(".user-login--form") do
      fill_in "username", with: login
      fill_in "password", with: password
      if autologin
        autologin_label = I18n.t("users.autologins.prompt",
                                 num_days: I18n.t("datetime.distance_in_words.x_days", count: Setting.autologin))
        check autologin_label
      end
      click_button I18n.t(:button_login)
    end
  end

  def logout
    # There are a select number of specs that rely on some implementation detail
    # of `visit signout_path` that a cookie clear just doesn't cut.
    if !using_cuprite? || RSpec.current_example.metadata[:signout_via_visit]
      visit signout_path
    else
      page.driver.cookies.clear
    end
  end

  private

  def js_enabled?
    RSpec.current_example.metadata[:js]
  end

  def using_cuprite?
    RSpec.current_example.metadata[:with_cuprite]
  end

  def session_value_for(user)
    { user_id: user.id, updated_at: Time.current }
  end

  module ClassMethods
    # Sets the current user.
    #
    # Will make the return value available in the specs as +current_user+ (using
    # a let block) and treat that user as the one currently being logged in.
    #
    # @block [Proc] The user to log in.
    def current_user(&)
      let(:current_user, &)

      before { login_as current_user }
    end

    # Sets the current user.
    #
    # This is the shared_let version of +current_user+, meaning the user is
    # created only once.
    #
    # Will make the return value available in the specs as +current_user+ (using
    # a shared_let block) and treat that user as the one currently being logged
    # in.
    #
    # @block [Proc] The user to log in.
    def shared_current_user(&)
      shared_let(:current_user, &)

      before { login_as current_user }
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers
end
