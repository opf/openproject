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

require "spec_helper"

RSpec.describe "rendering the login buttons for all providers" do
  helper OmniauthHelper
  let(:providers) do
    [
      { name: "mock_auth" },
      { name: "test_auth", display_name: "Test" },
      { name: "foob_auth", display_name: "Foobar", icon: "auth_provider-saml.png" }
    ]
  end

  before do
    allow(OpenProject::Plugins::AuthPlugin).to receive(:providers).and_return(providers)

    render partial: "hooks/login/providers", handlers: [:erb], formats: [:html]
  end

  it "shows the mock_auth button with the name as its label" do
    expect(rendered).to have_link(text: "Continue with #{providers[0][:name]}")
  end

  it "shows the test_auth button with the given display_name as its label" do
    expect(rendered).to have_link(text: "Continue with #{providers[1][:display_name]}")
  end

  it "renders the provider icon inside the button" do
    expect(rendered).to have_css("a.auth-provider-foob_auth img.auth-provider-icon")
  end

  it "renders no icon for providers without one" do
    expect(rendered).to have_no_css("a.auth-provider-mock_auth img")
  end

  it "keeps the button content free of block level elements" do
    expect(rendered).to have_no_css("a.auth-provider div")
  end

  it "links to the OmniAuth start form" do
    expect(rendered).to have_link(href: "/login/omniauth/mock_auth")
  end

  context "with an icon that cannot be resolved" do
    let(:providers) do
      [
        { name: "mock_auth" },
        { name: "foob_auth", display_name: "Foobar", icon: "there-is-no-such-asset.png" }
      ]
    end

    it "still renders every provider button, without the icon" do
      expect(rendered).to have_link(text: "Continue with Foobar")
      expect(rendered).to have_link(text: "Continue with mock_auth")
      expect(rendered).to have_no_css("img")
    end
  end

  context "with relative url root", with_config: { rails_relative_url_root: "/foobar" } do
    it "renders correctly" do
      expect(rendered).to include "/foobar/login/omniauth/mock_auth"
    end
  end
end
