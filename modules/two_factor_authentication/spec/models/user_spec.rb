# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

module OpenProject::TwoFactorAuthentication::Patches
  module UserSpec
    RSpec.describe User do
      def create_user(ldap_auth_source_id = nil)
        @user = build(:user)
        @username = @user.login
        @password = @user.password
        @user.ldap_auth_source_id = ldap_auth_source_id
        @user.save!
      end

      def create_user_with_auth_source
        auth_source = LdapAuthSource.new name: "test"
        create_user auth_source.id
      end

      def valid_login
        login_with @username, @password
      end

      def invalid_login
        login_with @username, @password + "INVALID"
      end

      def login_with(login, password)
        User.try_to_login(login, password)
      end

      before (:each) do
        create_user
      end

      describe "#try_to_login", "with valid username but invalid pwd" do
        it "returns nil" do
          expect(invalid_login).to be_nil
        end

        it "returns the user" do
          expect(valid_login).to eq(@user)
        end
      end
    end
  end
end
