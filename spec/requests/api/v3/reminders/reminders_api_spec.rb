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

RSpec.describe API::V3::Reminders::RemindersAPI do
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:user_with_permissions) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:other_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:other_user_without_permissions) { create(:user, member_with_permissions: { project: %i[view_projects] }) }

  describe "GET /api/v3/reminders" do
    let!(:user_reminders) do
      create_list(:reminder, 2, creator: user_with_permissions, remind_at: 1.day.from_now, remindable: work_package)
    end

    let!(:user_reminders_completed) do
      create_list(:reminder, 2, creator: user_with_permissions, remind_at: 1.day.ago, completed_at: 1.day.ago,
                                remindable: work_package)
    end

    let(:path) { api_v3_paths.reminders }

    context "with logged in user" do
      current_user { user_with_permissions }

      before { get path }

      it_behaves_like "API V3 collection response", 2, 2, "Reminder" do
        let(:elements) { user_reminders }
      end
    end

    it_behaves_like "handling anonymous user"
  end

  describe "PATCH /api/v3/reminders/:id" do
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }

    let!(:reminder) { create(:reminder, remindable: work_package, creator: user_with_permissions) }
    let!(:other_user_reminder) { create(:reminder, remindable: work_package, creator: other_user_without_permissions) }
    let!(:completed_reminder) do
      create(:reminder, :completed, remindable: work_package, creator: user_with_permissions)
    end

    def make_request
      patch path, params.to_json, headers
    end

    context "with permissions updating own reminder" do
      let(:path) { api_v3_paths.reminder(reminder.id) }
      let(:params) { { note: "UPDATED reminder note!" } }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "successful response", 200, "Reminder" do
        it "returns updated reminder attributes" do
          expect(last_response.body)
            .to be_json_eql("UPDATED reminder note!".to_json)
            .at_path("note")
        end
      end
    end

    context "with permissions updating completed reminder" do
      let(:path) { api_v3_paths.reminder(completed_reminder.id) }
      let(:params) { { note: "UPDATED reminder note!" } }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end

    context "with permissions updating other user's reminder" do
      let(:path) { api_v3_paths.reminder(other_user_reminder.id) }
      let(:params) { { note: "CANNOT update!" } }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end

    context "with no permissions updating own reminder" do
      let(:path) { api_v3_paths.reminder(other_user_reminder.id) }
      let(:params) { { note: "UPDATED reminder note!" } }

      current_user { other_user_without_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end
  end

  describe "DELETE /api/v3/reminders/:id" do
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }

    let(:reminder) { create(:reminder, remindable: work_package, creator: user_with_permissions) }
    let(:other_user_reminder) { create(:reminder, remindable: work_package, creator: other_user_without_permissions) }

    let(:completed_reminder) do
      create(:reminder, :completed, remindable: work_package, creator: user_with_permissions)
    end

    def make_request
      delete path, headers
    end

    context "with permissions deleting own reminder" do
      let(:path) { api_v3_paths.reminder(reminder.id) }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "successful no content response"
    end

    context "with permissions deleting completed reminder" do
      let(:path) { api_v3_paths.reminder(completed_reminder.id) }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end

    context "with permissions deleting other user's reminder" do
      let(:path) { api_v3_paths.reminder(other_user_reminder.id) }

      current_user { user_with_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end

    context "with no permissions deleting own reminder" do
      let(:path) { api_v3_paths.reminder(other_user_reminder.id) }

      current_user { other_user_without_permissions }

      before { make_request }

      it_behaves_like "error response",
                      404, "NotFound",
                      "The reminder you are looking for cannot be found or has been deleted."
    end
  end
end
