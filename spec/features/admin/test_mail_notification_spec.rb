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

RSpec.describe "Test mail notification", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }

  before do
    login_as admin
    visit admin_settings_mail_notifications_path(tab: :notifications)
  end

  it "shows the correct message on errors in test notification (Regression #28226)" do
    error_message = '"error" with <strong>Markup?</strong>'
    expect(UserMailer).to receive(:test_mail).with(admin)
      .and_raise error_message

    click_link "Send a test email"

    expected = "An error occurred while sending mail (#{error_message})"
    expect(page).to have_css(".op-toast.-error", text: expected)
    expect(page).to have_no_css(".op-toast.-error strong")
  end
end
