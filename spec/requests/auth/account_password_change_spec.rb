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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Account password change",
               :skip_csrf,
               type: :rails_request do
  let(:old_password) { "adminADMIN!" }
  let(:new_password) { "NewPassword!456" }
  let(:user) do
    create(:user,
           password: old_password,
           password_confirmation: old_password,
           force_password_change: false)
  end

  def post_account_password_change(login: user.login, password: old_password, **request_options)
    post "/account/change_password",
         params: {
           password_change_user: login,
           password:,
           new_password:,
           new_password_confirmation: new_password
         },
         **request_options
  end

  describe "POST /account/change_password" do
    it "keeps the current password when the account is not required to replace it" do
      post_account_password_change

      expect(user.reload.check_password?(old_password)).to be true
      expect(user.check_password?(new_password)).to be false
      expect(session[:user_id]).to be_nil
    end

    it "replaces the password when a replacement is required" do
      user.update_column(:force_password_change, true)

      post_account_password_change

      expect(user.reload.check_password?(new_password)).to be true
      expect(user.check_password?(old_password)).to be false
    end

    it "replaces the password when the current one is expired",
       with_settings: { password_days_valid: 1 } do
      user.current_password.update_column(:created_at, 2.days.ago)

      post_account_password_change

      expect(user.reload.check_password?(new_password)).to be true
      expect(user.check_password?(old_password)).to be false
    end

    it "replaces the password from the signed-in account page" do
      login_as(user)

      post "/my/change_password",
           params: {
             password: old_password,
             new_password:,
             new_password_confirmation: new_password
           }

      expect(user.reload.check_password?(new_password)).to be true
      expect(user.check_password?(old_password)).to be false
    end
  end

  describe "repeated attempts",
           :with_rack_attack,
           with_config: { rate_limiting: { login: { burst_limit: 3, burst_period: 3600 } } } do
    def allow_three_then_once
      freeze_time do
        3.times do
          yield
          expect(response).not_to have_http_status(:too_many_requests)
        end

        yield
      end
    end

    def post_json(path, params)
      post path,
           params: params.to_json,
           headers: { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "text/html" }
    end

    it "limits repeated attempts to replace one account password" do
      allow_three_then_once { post_account_password_change(password: "wrong") }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits repeated attempts when the account is only in the query string" do
      allow_three_then_once do
        post "/account/change_password?password_change_user=#{user.login}",
             params: {
               password: "wrong",
               new_password:,
               new_password_confirmation: new_password
             }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits repeated sign-in attempts when the login is only in the query string" do
      allow_three_then_once { post "/login?username=#{user.login}", params: { password: "wrong" } }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits the account named in the query when the form names a different one" do
      allow_three_then_once do
        post "/login?username=#{user.login}", params: { username: "other-login", password: "wrong" }
      end

      post "/login", params: { username: user.login, password: "wrong" }

      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits repeated sign-in attempts when the login is sent as JSON" do
      allow_three_then_once do
        post_json "/login?format=html", username: user.login, password: "wrong"
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it "limits repeated password changes when the account is sent as JSON" do
      allow_three_then_once do
        post_json "/account/change_password?format=html",
                  password_change_user: user.login,
                  password: "wrong",
                  new_password:,
                  new_password_confirmation: new_password
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "failed attempt counter" do
    it "counts each failed attempt recorded from separate copies of the account" do
      user.update_columns(failed_login_count: 0, last_failed_login_on: 1.minute.ago)

      copies = Array.new(2) { User.find(user.id) }
      copies.each(&:log_failed_login)

      expect(user.reload.failed_login_count).to eq(2)
    end
  end
end
