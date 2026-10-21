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

RSpec.describe "PWA offline page", :js, with_flag: { progressive_web_app: true } do
  let(:network) { page.driver.browser.network }

  after do
    network.emulate_network_conditions(offline: false, latency: 0, download_throughput: -1, upload_throughput: -1)
  end

  it "reports that the connection is still down and lets the user retry again" do
    visit "/offline"
    network.offline_mode

    click_on "Retry"

    expect(page).to have_text("Still offline. We’ll try again in a moment.")
    expect(find_button("Retry")["aria-busy"]).to eq("false")
  end

  it "announces the restored connection and leaves the offline page for the home page" do
    visit "/offline"

    click_on "Retry"

    expect(page).to have_heading("You’re back online")
    expect(page).to have_text("Connection restored. Reloading…")
    expect(page).to have_no_current_path("/offline")
  end

  it "ignores further clicks while a check is running" do
    visit "/offline"
    network.emulate_network_conditions(latency: 60_000)

    click_on "Retry"
    expect(page).to have_button("Retrying…")
    click_on "Retrying…"

    button = find_button("Retrying…")
    expect(button["aria-busy"]).to eq("true")
    expect(button["aria-disabled"]).to eq("true")
  end
end
