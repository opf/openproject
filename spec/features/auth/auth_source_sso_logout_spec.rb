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

Capybara.register_driver :auth_source_sso do |app|
  Capybara::RackTest::Driver.new(app, headers: { "HTTP_X_REMOTE_USER" => "bob" })
end

RSpec.describe "Login with auth source SSO",
               driver: :auth_source_sso do
  let(:sso_config) do
    {
      header: "X-Remote-User",
      logout_url: "http://google.com/"
    }
  end

  let!(:user) { create(:user, login: "bob") }

  before do
    allow(OpenProject::Configuration)
      .to receive(:auth_source_sso)
            .and_return(sso_config)
    allow(LdapAuthSource).to receive(:find_user).with("bob").and_return(user)
  end

  it "can log out after multiple visits" do
    visit home_path

    expect(page).to have_css(".controller-homescreen")

    visit home_path

    expect(page).to have_css(".controller-homescreen")

    visit signout_path

    expect(current_url).to eq "http://google.com/"
  end
end
