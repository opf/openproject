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
  let(:offline_path) { "/offline" }

  def stub_fetch(body)
    page.execute_script(<<~JS)
      window.__fetchUrls = [];
      window.fetch = (...args) => {
        window.__fetchUrls.push(args[0]);
        #{body}
      };
    JS
  end

  def respond_ok = "return Promise.resolve({ ok: true });"
  def fail_network = "return Promise.reject(new TypeError('Failed to fetch'));"
  def hang_until_released = "return new Promise((resolve) => { window.__release = () => resolve({ ok: true }); });"

  def offline_text(key) = I18n.t("pwa.offline.#{key}")

  it "reports that the connection is still down and lets the user retry again" do
    visit offline_path
    stub_fetch(fail_network)

    click_on offline_text("retry")

    expect(page).to have_text(offline_text("status_still"))
    expect(find_button(offline_text("retry"))["aria-busy"]).to eq("false")
  end

  it "announces the restored connection and leaves the offline page for the home page" do
    visit offline_path
    stub_fetch(respond_ok)
    page.execute_script("window.__sameDocument = true")

    click_on offline_text("retry")

    expect(page).to have_heading(offline_text("headline_online"))
    expect(page.evaluate_script("window.__fetchUrls")).to eq([offline_path])
    expect(page).to have_text(offline_text("status_restored"))
    expect(page).to have_no_current_path(offline_path)
    expect(page.evaluate_script("window.__sameDocument")).to be_nil
  end

  it "ignores further clicks while a check is running" do
    visit offline_path
    stub_fetch(hang_until_released)

    click_on offline_text("retry")
    expect(page).to have_button(offline_text("retrying"))
    click_on offline_text("retrying")

    expect(find_button(offline_text("retrying"))).to match_css("[aria-busy='true'][aria-disabled='true']")
    expect(page.evaluate_script("window.__fetchUrls.length")).to eq(1)
  end
end
