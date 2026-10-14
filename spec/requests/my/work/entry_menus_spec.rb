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

RSpec.describe "My work entry menus", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking costs]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_project view_work_packages log_own_time edit_own_time_entries] })
  end

  current_user { user }

  describe "GET /my/work/entry_menus/time_entries/:id" do
    let(:time_entry) { create(:time_entry, user:, entity: work_package) }

    before { get my_work_time_entry_menu_path(time_entry) }

    it "renders the items of the time entry's menu without a layout" do
      expect(response).to have_http_status(:ok)
      expect(page).to have_css("ul[role='menu']")
      expect(page).to have_link("Open work package", href: work_package_path(work_package))
      expect(page).to have_link("Edit time entry")
      expect(page).to have_no_css("action-menu")
      expect(response.body).not_to include("<html")
    end

    context "when the time entry belongs to someone else" do
      let(:time_entry) { create(:time_entry, user: create(:user), entity: work_package) }

      it "is not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /my/work/entry_menus/allocations/:id/:date", with_ee: %i[resource_management] do
    let(:monday) { Date.new(2026, 1, 5) }
    let(:date) { monday.iso8601 }
    let(:allocated_work_package) { work_package }
    let!(:allocation) do
      create(:resource_allocation, principal: user, entity: allocated_work_package, allocated_time: 480,
                                   start_date: monday, end_date: monday)
    end

    before do
      create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
      create(:time_entry, user:, entity: work_package, spent_on: monday, hours: 2)

      get my_work_allocation_menu_path(allocation, date:)
    end

    it "renders the items of the allocation's menu with what is left of it" do
      expect(response).to have_http_status(:ok)
      expect(page).to have_css("ul[role='menu']")
      expect(page).to have_link("Open work package", href: work_package_path(work_package))
      expect(page.find_link("Log time from allocation")[:href]).to include("hours=6.0")
      expect(response.body).not_to include("<html")
    end

    context "when nothing is scheduled for it on that date" do
      let(:date) { (monday + 1.day).iso8601 }

      it "is not found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user cannot see its work package" do
      let(:allocated_work_package) { create(:work_package) }

      it "is not found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a date that does not exist" do
      let(:date) { "2026-13-45" }

      it "is not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
