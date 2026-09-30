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

require_relative "../../../spec_helper"
require_relative "../authentication_controller_shared_examples"

RSpec.describe TwoFactorAuthentication::My::RememberCookieController do
  let(:user) { create(:user, login: "foobar") }
  let(:logged_in_user) { user }

  before do
    allow(User).to receive(:current).and_return(logged_in_user)
  end

  describe "#destroy" do
    before do
      delete :destroy
    end

    context "when not logged in" do
      let(:logged_in_user) { User.anonymous }

      it "does not give access" do
        expect(response).to be_redirect
        expect(response).to redirect_to signin_path(back_url: my_2fa_remember_cookie_url)
      end
    end

    context "when logged in and active strategies" do
      it "renders the index page" do
        expect(response).to be_redirect
        expect(flash[:notice]).to be_present
      end
    end
  end
end
