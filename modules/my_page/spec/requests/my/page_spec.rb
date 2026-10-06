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

RSpec.describe "My page", type: :rails_request do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let(:path) { my_page_path }

  current_user { user }

  subject { get path }

  context "without the my_day flag" do
    it "shows the dashboard without tabs" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("opce-my-page")
      expect(page).not_to have_test_selector("my-page-tabs")
      expect(Project.count).to eq(0)
    end
  end

  context "with the my_day flag", with_flag: { my_day: true } do
    around { |example| travel_to(Time.zone.parse("2026-10-06 08:00")) { example.run } }

    let(:meeting_project) { create(:project, enabled_module_names: %w[meetings work_package_tracking]) }
    let!(:meeting) do
      create(:meeting, project: meeting_project, title: "XWiki daily", duration: 0.25,
                       start_time: user.time_zone.parse("#{user.today} 09:30"))
    end
    let(:referenced) { create(:work_package, project: meeting_project, subject: "Show GitLab branches") }
    let!(:work_package) do
      create(:work_package, project: MyDay::ProjectService.new(user).call.result, type: task,
                            subject: "Book train to the offsite", due_date: user.today)
    end
    let!(:task_with_reference) do
      create(:work_package, project: MyDay::ProjectService.new(user).call.result, type: task,
                            subject: "Write down questions on ##{referenced.id} for the sync", due_date: user.today)
    end

    before do
      create(:member, project: meeting_project, principal: user,
                      roles: [create(:project_role, permissions: %i[view_meetings view_work_packages])])
      create(:meeting_participant, meeting:, user:)
    end

    it "opens on Today" do
      subject

      expect(page).to have_test_selector("my-day-meeting-morning", text: "09:30 AM–09:45 AM")
      expect(page).to have_test_selector("my-day-meeting-duration", text: "15 mins")
      expect(page).to have_test_selector("my-day-reference", text: "Show GitLab branches")

      expect(page).to have_test_selector("my-page-tabs")
      expect(page).to have_test_selector("my-day-today")
      expect(page).to have_test_selector("my-day-quick-add")
      expect(page).to have_css("segmented-control [aria-current=true]", text: "Morning")
      expect(page).to have_test_selector("my-day-task-morning", text: "Book train to the offsite")
      expect(page).to have_test_selector("my-day-empty-afternoon", text: "Nothing planned.")
      expect(response.body).not_to include("opce-my-page")
    end

    context "on the dashboard tab" do
      let(:path) { my_page_path(tab: :dashboard) }

      it "shows the widget grid" do
        subject

        expect(page).to have_test_selector("my-page-tabs")
        expect(page).not_to have_test_selector("my-day-today")
        expect(response.body).to include("opce-my-page")
      end
    end
  end
end
