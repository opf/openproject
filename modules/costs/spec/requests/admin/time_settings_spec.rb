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

RSpec.describe "Time settings",
               :skip_csrf,
               type: :rails_request do
  let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  describe "GET /admin/time" do
    context "without an Enterprise token" do
      it "disables the restriction fields" do
        get "/admin/time"

        expect(response).to have_http_status(:success)
        expect(page).to have_field(I18n.t(:setting_time_entries_max_hours_per_entry), disabled: true)
        expect(page).to have_field(I18n.t(:setting_time_entries_max_hours_per_day), disabled: true)
        expect(page).to have_field(I18n.t(:setting_time_entries_prohibit_logging_on_non_working_days), disabled: true)
        expect(page).to have_field(I18n.t(:setting_time_entries_limit_to_user_working_hours), disabled: true)
        expect(page).to have_field(I18n.t(:setting_time_entries_prohibit_logging_for_past_months), disabled: true)
      end
    end

    context "with an Enterprise token", with_ee: %i[time_entry_time_restrictions] do
      it "allows editing the restriction fields" do
        get "/admin/time"

        expect(response).to have_http_status(:success)
        expect(page).to have_field(I18n.t(:setting_time_entries_max_hours_per_entry), disabled: false)
        expect(page).to have_field(I18n.t(:setting_time_entries_max_hours_per_day), disabled: false)
        expect(page).to have_field(I18n.t(:setting_time_entries_prohibit_logging_on_non_working_days), disabled: false)
        expect(page).to have_field(I18n.t(:setting_time_entries_limit_to_user_working_hours), disabled: false)
        expect(page).to have_field(I18n.t(:setting_time_entries_prohibit_logging_for_past_months), disabled: false)
      end

      it "disables the grace period while logging for past months is not prohibited" do
        Setting.time_entries_prohibit_logging_for_past_months = false
        get "/admin/time"

        expect(page).to have_field(I18n.t(:setting_time_entries_past_month_grace_days), disabled: true)
      end

      it "enables the grace period once logging for past months is prohibited" do
        Setting.time_entries_prohibit_logging_for_past_months = true
        get "/admin/time"

        expect(page).to have_field(I18n.t(:setting_time_entries_past_month_grace_days), disabled: false)
      end
    end
  end

  describe "PATCH /admin/time" do
    it "updates the restrictions" do
      settings = { time_entries_max_hours_per_entry: "8",
                   time_entries_max_hours_per_day: "10",
                   time_entries_prohibit_logging_on_non_working_days: "1",
                   time_entries_limit_to_user_working_hours: "1",
                   time_entries_prohibit_logging_for_past_months: "1",
                   time_entries_past_month_grace_days: "5" }
      patch "/admin/time", params: { settings: }

      expect(response).to redirect_to(action: :show)
      expect(Setting.time_entries_max_hours_per_entry).to eq(8)
      expect(Setting.time_entries_max_hours_per_day).to eq(10)
      expect(Setting.time_entries_prohibit_logging_on_non_working_days).to be(true)
      expect(Setting.time_entries_limit_to_user_working_hours).to be(true)
      expect(Setting.time_entries_prohibit_logging_for_past_months).to be(true)
      expect(Setting.time_entries_past_month_grace_days).to eq(5)
    end
  end
end
