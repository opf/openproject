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
      it "disables the maximum hours per time entry field" do
        get "/admin/time"

        expect(response).to have_http_status(:success)
        expect(page).to have_field(I18n.t(:setting_max_hours_per_time_entry), disabled: true)
      end
    end

    context "with an Enterprise token", with_ee: %i[time_entry_time_restrictions] do
      it "allows editing the maximum hours per time entry" do
        get "/admin/time"

        expect(response).to have_http_status(:success)
        expect(page).to have_field(I18n.t(:setting_max_hours_per_time_entry), disabled: false)
      end
    end
  end

  describe "PATCH /admin/time" do
    it "updates the maximum hours per time entry" do
      patch "/admin/time", params: { settings: { max_hours_per_time_entry: "8" } }

      expect(response).to redirect_to(action: :show)
      expect(Setting.max_hours_per_time_entry).to eq(8)
    end
  end
end
