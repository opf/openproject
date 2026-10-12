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

RSpec.describe "datetime custom field inplace editor",
               :js,
               with_settings: { date_format: "%Y-%m-%d", time_format: "%H:%M" } do
  let(:user) { create(:admin, preferences: { time_zone: "Europe/Brussels" }) }
  let(:custom_field) { create(:datetime_wp_custom_field, name: "Detected at") }
  let(:type) { create(:type_task, custom_fields: [custom_field]) }
  let(:project) { create(:project, types: [type]) }
  let(:work_package) do
    create(:work_package, type:, project:, custom_values: { custom_field.id => "2026-10-01 12:30:00" })
  end
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:property_name) { custom_field.attribute_name(:camel_case) }
  let(:field) { wp_page.edit_field(property_name) }

  current_user { user }

  before do
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "shows and edits the value in the user's time zone and stores it in UTC" do
    field.expect_state_text "2026-10-01 14:30"

    field.activate!
    expect(field.input_element.value).to eq("2026-10-01T14:30")

    field.input_element.set("2026-12-24T09:15")
    field.submit_by_enter

    wp_page.expect_toast(message: I18n.t("js.notice_successful_update"))
    field.expect_state_text "2026-12-24 09:15"

    expect(work_package.reload.typed_custom_value_for(custom_field)).to eq(Time.utc(2026, 12, 24, 8, 15))

    page.driver.refresh
    wp_page.ensure_page_loaded
    wp_page.edit_field(property_name).expect_state_text "2026-12-24 09:15"
  end

  it "clears the value" do
    field.activate!
    field.input_element.set("")
    field.submit_by_enter

    wp_page.expect_toast(message: I18n.t("js.notice_successful_update"))
    field.expect_state_text "-"

    expect(work_package.reload.typed_custom_value_for(custom_field)).to be_nil
  end
end
