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

RSpec.describe "Admin announcement" do
  shared_let(:admin) { create(:admin) }
  let!(:announcement) do
    create(:announcement, text: "Hello world", show_until: Date.new(2026, 12, 24), active: true)
  end

  before { login_as(admin) }

  it "shows the current announcement and allows updating it" do
    visit "/admin/announcements/edit"

    expect(page).to have_field("announcement_text", type: "textarea", with: "Hello world", visible: :all)
    expect(page).to have_css(%(opce-basic-single-date-picker[data-value='"2026-12-24"']), visible: :all)
    expect(page).to have_checked_field("Active")

    uncheck "Active"
    click_button "Save"

    expect(page).to have_current_path("/admin/announcements/edit")
    expect_flash(message: I18n.t(:notice_successful_update))
    expect(page).to have_unchecked_field("Active")

    announcement.reload
    expect(announcement.active).to be(false)
    expect(announcement.text).to eq("Hello world")
    expect(announcement.show_until).to eq(Date.new(2026, 12, 24))
  end
end
