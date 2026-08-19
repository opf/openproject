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

RSpec.describe "Updating internal wiki provider", :js, :selenium, driver: :firefox_en do
  shared_let(:admin) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  shared_let(:auth_provider) { create(:oidc_provider) }

  let!(:provider) { create(:internal_wiki_provider, enabled: true) }

  current_user { admin }

  it "can enable and disable the internal provider", :aggregate_failures, with_ee: [:scim_api] do
    visit admin_settings_internal_wiki_provider_path
    expect(page).to be_axe_clean.within("#content")

    expect(page).to have_checked_field("Enable the internal OpenProject wiki")

    uncheck "Enable the internal OpenProject wiki"
    click_on "Save"

    SeleniumHubWaiter.wait

    expect(page).to have_unchecked_field("Enable the internal OpenProject wiki")
    expect(provider.reload).not_to be_enabled

    check "Enable the internal OpenProject wiki"
    click_on "Save"

    SeleniumHubWaiter.wait

    expect(page).to have_checked_field("Enable the internal OpenProject wiki")
    expect(provider.reload).to be_enabled
  end
end
