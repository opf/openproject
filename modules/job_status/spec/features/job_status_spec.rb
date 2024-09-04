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

RSpec.describe "Job status", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as admin
  end

  it "renders a descriptive error in case of 404" do
    visit "/job_statuses/something-that-does-not-exist"

    expect(page).to have_css(".octicon-x-circle", wait: 10)
    expect(page).to have_content I18n.t("job_status_dialog.generic_messages.not_found")
  end

  describe "with a status that has an additional errors payload" do
    let!(:status) { create(:delayed_job_status, user: admin) }

    before do
      status.update! payload: { errors: ["Some error", "Another error"] }
    end

    it "shows a list of these errors" do
      visit "/job_statuses/#{status.job_id}"

      expect(page).to have_css(".octicon-x-circle", wait: 10)
      expect(page).to have_content I18n.t("job_status_dialog.errors")
      expect(page).to have_content "Some error"
      expect(page).to have_content "Another error"
    end
  end

  describe "with a status without error and redirect" do
    let!(:status) { create(:delayed_job_status, user: admin) }

    before do
      status.update! payload: { redirect: home_url }
    end

    it "does automatically redirect" do
      visit "/job_statuses/#{status.job_id}"

      expect(page).to have_current_path(home_path, wait: 10)
    end
  end

  describe "with a status with error and redirect" do
    let!(:status) { create(:delayed_job_status, user: admin) }

    before do
      status.update! payload: { redirect: home_url, errors: ["Some error"] }
    end

    it "does not automatically redirect" do
      visit "/job_statuses/#{status.job_id}"

      expect(page).to have_css(".octicon-x-circle", wait: 10)
      expect(page).to have_content I18n.t("job_status_dialog.errors")
      expect(page).to have_content "Some error"
      expect(page).to have_css("a[href='#{home_url}']", text: "Please click here to continue")
    end

    it "does not navigate back after user clicked the redirect" do
      visit "/projects"
      visit "/job_statuses/#{status.job_id}"
      click_on I18n.t("job_status_dialog.redirect_link")

      expect(page).to have_current_path(home_path, wait: 10)
    end
  end
end
