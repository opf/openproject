#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::Notifications::NotificationsAPI,
               "index", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:work_package) { create(:work_package) }
  shared_let(:recipient) do
    create(:user,
           member_with_permissions: { work_package.project => %i[view_work_packages] })
  end
  shared_let(:mentioned_notification) do
    create(:notification,
           recipient:,
           resource: work_package,
           journal: work_package.journals.first)
  end
  shared_let(:date_alert_notification) do
    create(:notification,
           recipient:,
           reason: :date_alert_start_date,
           resource: work_package)
  end

  let(:filters) { nil }

  let(:send_request) do
    get api_v3_paths.path_for :notifications, filters:
  end

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:additional_setup) do
    # To be overwritten by individual specs
  end

  before do
    login_as current_user
    additional_setup

    send_request
  end

  describe "as the user with notifications" do
    let(:current_user) { recipient }

    it_behaves_like "API V3 collection response", 2, 2, "Notification" do
      let(:elements) { [date_alert_notification, mentioned_notification] }
    end

    context "with a readIAN filter" do
      let(:nil_notification) { create(:notification, recipient:, read_ian: nil) }

      let(:filters) do
        [
          {
            "readIAN" => {
              "operator" => "=",
              "values" => ["f"]

            }
          }
        ]
      end

      context "with the filter being set to false" do
        it_behaves_like "API V3 collection response", 2, 2, "Notification" do
          let(:elements) { [date_alert_notification, mentioned_notification] }
        end
      end
    end

    context "with a resource filter" do
      shared_let(:other_work_package) { create(:work_package, project: work_package.project) }
      shared_let(:other_resource_notification) do
        create(:notification,
               recipient:,
               resource: other_work_package)
      end

      let(:filters) do
        [
          {
            "resourceId" => {
              "operator" => "=",
              "values" => [other_work_package.id.to_s]
            }
          },
          {
            "resourceType" => {
              "operator" => "=",
              "values" => [WorkPackage.name.to_s]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Notification" do
        let(:elements) { [other_resource_notification] }
      end
    end

    context "with a project filter" do
      shared_let(:other_project) do
        create(:project,
               members: { recipient => recipient.members.first.roles })
      end
      shared_let(:other_work_package) { create(:work_package, project: other_project) }
      shared_let(:other_project_notification) do
        create(:notification,
               recipient:,
               resource: other_work_package)
      end

      let(:filters) do
        [
          {
            "project" => {
              "operator" => "=",
              "values" => [other_work_package.project_id.to_s]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "Notification" do
        let(:elements) { [other_project_notification] }
      end
    end

    context "with a reason filter", with_ee: %i[date_alerts] do
      shared_let(:assigned_notification) do
        create(:notification,
               reason: :assigned,
               recipient:,
               resource: work_package,
               journal: work_package.journals.first)
      end
      shared_let(:responsible_notification) do
        create(:notification,
               reason: :responsible,
               recipient:,
               resource: work_package,
               journal: work_package.journals.first)
      end

      let(:filters) do
        [
          {
            "reason" => {
              "operator" => "=",
              "values" => [mentioned_notification.reason.to_s, responsible_notification.reason.to_s, "dateAlert"]
            }
          }
        ]
      end

      it_behaves_like "API V3 collection response", 3, 3, "Notification" do
        let(:elements) { [responsible_notification, date_alert_notification, mentioned_notification] }
      end

      context "when using date alerts without enterprise", with_ee: false do
        let(:filters) do
          [
            {
              "reason" => {
                "operator" => "=",
                "values" => ["dateAlert"]
              }
            }
          ]
        end

        it "returns an error" do
          expect(last_response.status)
            .to be 400

          expect(last_response.body)
            .to be_json_eql("Filters Reason filter has invalid values.".to_json)
                  .at_path("message")
        end
      end

      context "with an invalid reason" do
        let(:filters) do
          [
            {
              "reason" => {
                "operator" => "=",
                "values" => ["bogus"]
              }
            }
          ]
        end

        it "returns an error" do
          expect(last_response.status)
            .to be 400

          expect(last_response.body)
            .to be_json_eql("Filters Reason filter has invalid values.".to_json)
                  .at_path("message")
        end
      end
    end

    context "with a non ian notification" do
      shared_let(:wiki_page) { create(:wiki_page) }

      shared_let(:non_ian_notification) do
        create(:notification,
               read_ian: nil,
               recipient:,
               resource: wiki_page,
               journal: wiki_page.journals.first)
      end

      it_behaves_like "API V3 collection response", 2, 2, "Notification" do
        let(:elements) { [date_alert_notification, mentioned_notification] }
      end
    end

    context "with a reason groupBy" do
      shared_let(:responsible_notification) do
        create(:notification,
               recipient:,
               reason: :responsible,
               resource: work_package,
               journal: work_package.journals.first)
      end

      shared_let(:due_date_alert_notification) do
        create(:notification,
               recipient:,
               reason: :date_alert_due_date,
               resource: work_package)
      end

      let(:send_request) do
        get api_v3_paths.path_for :notifications, group_by: :reason
      end

      let(:groups) { parsed_response["groups"] }

      it_behaves_like "API V3 collection response", 4, 4, "Notification" do
        let(:elements) do
          [mentioned_notification, responsible_notification, date_alert_notification, due_date_alert_notification]
        end
      end

      it "contains the reason groups", :aggregate_failures do
        expect(groups).to be_a Array
        expect(groups.count).to eq 3

        keyed = groups.index_by { |el| el["value"] }
        expect(keyed.keys).to contain_exactly "mentioned", "responsible", "dateAlert"
        expect(keyed["mentioned"]["count"]).to eq 1
        expect(keyed["responsible"]["count"]).to eq 1
        expect(keyed["dateAlert"]["count"]).to eq 2
      end
    end

    context "with a project groupBy" do
      shared_let(:other_project) do
        create(:project,
               members: { recipient => recipient.members.first.roles })
      end
      shared_let(:work_package2) { create(:work_package, project: other_project) }
      shared_let(:other_project_notification) do
        create(:notification,
               resource: work_package2,
               recipient:,
               reason: :responsible,
               journal: work_package2.journals.first)
      end

      let(:send_request) do
        get api_v3_paths.path_for :notifications, group_by: :project
      end

      let(:groups) { parsed_response["groups"] }

      it_behaves_like "API V3 collection response", 3, 3, "Notification"

      it "contains the project groups", :aggregate_failures do
        expect(groups).to be_a Array
        expect(groups.count).to eq 2

        keyed = groups.index_by { |el| el["value"] }
        expect(keyed.keys).to contain_exactly other_project.name, work_package.project.name
        expect(keyed[work_package.project.name]["count"]).to eq 2
        expect(keyed[work_package2.project.name]["count"]).to eq 1

        expect(keyed.dig(work_package.project.name, "_links", "valueLink")[0]["href"])
          .to eq "/api/v3/projects/#{work_package.project.id}"
      end
    end

    context "when having lost the permission to see the work package" do
      let(:additional_setup) do
        Member.where(principal: recipient).destroy_all
      end

      it_behaves_like "API V3 collection response", 0, 0, "Notification"
    end

    context "when signaling" do
      let(:select) { "total,count" }
      let(:send_request) do
        get api_v3_paths.path_for :notifications, select:
      end

      let(:expected) do
        {
          total: 2,
          count: 2
        }
      end

      it "is the reduced set of properties of the embedded elements" do
        expect(last_response.body)
          .to be_json_eql(expected.to_json)
      end
    end
  end

  describe "admin user" do
    let(:current_user) { build(:admin) }

    it_behaves_like "API V3 collection response", 0, 0, "Notification"
  end

  describe "as any user" do
    let(:current_user) { build(:user) }

    it_behaves_like "API V3 collection response", 0, 0, "Notification"
  end

  describe "as an anonymous user" do
    let(:current_user) { User.anonymous }

    it_behaves_like "forbidden response based on login_required"
  end
end
