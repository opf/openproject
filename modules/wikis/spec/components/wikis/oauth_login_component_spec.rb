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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::OAuthLoginComponent, type: :component do
  let(:work_package) { build_stubbed(:work_package) }
  let(:provider) { create(:xwiki_provider) }
  let(:oauth_client) { create(:oauth_client, integration: provider) }

  let(:return_url) { "https://openproject.example.com/work_packages/#{work_package.id}?tab=wikis" }

  before do
    allow(provider).to receive(:oauth_client).and_return(oauth_client)
    render_inline(described_class.new(provider, return_url:, work_package:))
  end

  it "renders the heading" do
    expect(page).to have_text(I18n.t("wikis.oauth_login_component.heading", provider: provider.name))
  end

  it "renders the description" do
    expect(page).to have_text(I18n.t("wikis.oauth_login_component.description", provider: provider.name))
  end

  it "renders the connect button with the return url" do
    link = page.find_link(I18n.t("wikis.oauth_login_component.connect_button", provider: provider.name))
    expect(link[:href]).to match(/ensure_connection/)
    expect(link[:href]).to include(CGI.escape(return_url))
    expect(link[:"data-turbo-frame"]).to eq("_top")
  end
end
