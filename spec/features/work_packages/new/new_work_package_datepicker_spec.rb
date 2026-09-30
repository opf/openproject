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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "features/page_objects/notification"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "New work package datepicker",
               :js, with_settings: { date_format: "%Y-%m-%d" } do
  let(:project) { create(:project_with_types, public: true) }
  let(:user) { create(:admin) }

  let(:wp_page_create) { Pages::FullWorkPackageCreate.new(project:) }
  let(:date_field) { wp_page_create.edit_field(:combinedDate) }
  let(:datepicker) { date_field.datepicker }

  before do
    login_as(user)

    wp_page_create.visit!
    wait_for_reload
  end

  it "can open and select the datepicker" do
    date_field.input_element.click
    date_field.toggle_working_days_only

    start = (Time.zone.today - 1.day).iso8601
    wait_for_network_idle
    date_field.enable_start_date
    date_field.set_active_date start

    wait_for_network_idle

    due = (Time.zone.today + 1.day).iso8601
    date_field.focus_due_date
    date_field.set_active_date due

    date_field.expect_duration 3

    # Bug #62300 - Manual scheduling mode button can be clicked without producing a 500 error
    datepicker.click_manual_scheduling_mode

    # Bug #61960 - Automatic scheduling mode button can be clicked
    datepicker.click_automatic_scheduling_mode
    datepicker.expect_save_button_disabled
    datepicker.click_manual_scheduling_mode

    date_field.save!
    date_field.expect_inactive!
    date_field.expect_value "#{start} - #{due}"
  end
end
