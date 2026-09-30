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

RSpec.describe API::V3::Reminders::RemindersByWorkPackageAPI do
  include API::V3::Utilities::PathHelper

  let!(:project) { create(:project) }

  let!(:role_with_permissions) { create(:project_role, permissions: %i[view_work_packages]) }
  let!(:role_without_permissions) { create(:project_role, permissions: %i[view_project]) }

  let!(:user_with_permissions) do
    create(:user, member_with_roles: { project => role_with_permissions })
  end
  let!(:other_user_without_permissions) do
    create(:user, member_with_roles: { project => role_without_permissions })
  end

  let!(:work_package) { create(:work_package, project:) }
  let!(:other_work_package) { create(:work_package, project:) }

  let!(:user_with_permissions_past_reminder) do
    Reminders::CreateService.new(user: user_with_permissions, contract_class: nil)
                           .call(remindable: work_package,
                                 remind_at: 1.day.ago,
                                 creator: user_with_permissions,
                                 note: "I'm the user with permissions and my reminder is in the past")
                           .result
  end
  let!(:user_with_permissions_future_reminder) do
    Reminders::CreateService.new(user: user_with_permissions, contract_class: nil)
                           .call(remindable: work_package,
                                 remind_at: 1.day.from_now,
                                 creator: user_with_permissions,
                                 note: "I'm the user with permissions and my reminder is in the future")
                           .result
  end
  let!(:user_with_permissions_future_reminder_in_other_work_package) do
    Reminders::CreateService.new(user: user_with_permissions, contract_class: nil)
                           .call(remindable: other_work_package,
                                 remind_at: 1.day.from_now,
                                 creator: user_with_permissions,
                                 note: "I'm the user with permissions and my reminder is in the future in another work package")
                           .result
  end
  let!(:other_user_without_permissions_reminder) do
    Reminders::CreateService.new(user: other_user_without_permissions, contract_class: nil)
                           .call(remindable: other_work_package,
                                 remind_at: 1.day.from_now,
                                 creator: other_user_without_permissions,
                                 note: "I'm the other user without permissions and my reminder is in the future")
                           .result
  end
  let!(:other_user_without_permissions_reminder_past) do
    Reminders::CreateService.new(user: other_user_without_permissions, contract_class: nil)
                           .call(remindable: other_work_package,
                                 remind_at: 1.day.ago,
                                 creator: other_user_without_permissions,
                                 note: "I'm the other user without permissions and my reminder is in the past")
                           .result
  end
  let!(:other_user_without_permissions_reminder_in_other_work_package) do
    Reminders::CreateService.new(user: other_user_without_permissions, contract_class: nil)
                           .call(remindable: other_work_package,
                                 remind_at: 1.day.from_now,
                                 creator: other_user_without_permissions,
                                 note: "I'm the other user without permissions and my reminder is in the" \
                                       "future in another work package")
                           .result
  end

  describe "GET /api/v3/work_packages/:work_package_id/reminders" do
    let(:make_request) { get api_v3_paths.work_package_reminders(work_package.id) }

    context "with permissions" do
      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "API V3 collection response", 1, 1, "Reminder" do
        let(:elements) { [user_with_permissions_future_reminder] }

        it "returns the future reminders for the current user in the given work package" do
          expect(last_response.body)
            .to be_json_eql("I'm the user with permissions and my reminder is in the future".to_json)
            .at_path("_embedded/elements/0/note")

          expect(last_response.body)
            .to be_json_eql(
              API::V3::Utilities::DateTimeFormatter.format_datetime(user_with_permissions_future_reminder.remind_at).to_json
            )
            .at_path("_embedded/elements/0/remindAt")

          expect(last_response.body)
            .to be_json_eql({ "href" => "/api/v3/users/#{user_with_permissions.id}",
                              "title" => user_with_permissions.name }.to_json)
            .at_path("_embedded/elements/0/_links/creator")
        end
      end
    end

    context "with no permissions" do
      current_user { other_user_without_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The work package you are looking for cannot be found or has been deleted."
    end
  end

  describe "POST /api/v3/work_packages/:work_package_id/reminders", :freeze_time do
    let(:path) { api_v3_paths.work_package_reminders(work_package.id) }
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }
    let(:remind_at) { 1.day.from_now }
    let(:note) { "Remind me to do something" }
    let(:params) { { remindAt: remind_at, note: } }

    def make_request
      post path, params.to_json, headers
    end

    context "with permissions" do
      current_user { user_with_permissions }

      before do
        Reminder.destroy_all
        make_request
      end

      it_behaves_like "successful response", 201, "Reminder" do
        it "returns reminder attributes" do
          expect(last_response.body)
            .to be_json_eql(API::V3::Utilities::DateTimeFormatter.format_datetime(remind_at).to_json)
            .at_path("remindAt")

          expect(last_response.body)
            .to be_json_eql(note.to_json)
            .at_path("note")

          expect(last_response.body)
            .to be_json_eql({ "href" => "/api/v3/users/#{current_user.id}", "title" => current_user.name }.to_json)
            .at_path("_links/creator")
        end
      end
    end

    context "with an existing reminder" do
      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "error response",
                      409, "UpdateConflict",
                      "You can only set one reminder at a time for a work package. Please delete or update the existing reminder."
    end

    context "with no permissions" do
      current_user { other_user_without_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The work package you are looking for cannot be found or has been deleted."
    end
  end
end
