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

RSpec.describe API::V3::Notifications::NotificationCollectionRepresenter do
  let(:self_base_link) { "/api/v3/notifications" }
  let(:user) { build_stubbed(:user) }
  let(:notification_list) { build_stubbed_list(:notification, 3) }
  let(:notifications) do
    notification_list.tap do |items|
      without_partial_double_verification do
        allow(items)
        .to receive(:limit)
              .with(page_size)
              .and_return(items)

        allow(items)
          .to receive(:offset)
                .with(page - 1)
                .and_return(items)

        allow(items)
          .to receive(:count)
                .and_return(total)
      end
    end
  end
  let(:current_user) { build_stubbed(:user) }
  let(:representer) do
    described_class.new(notifications,
                        self_link: self_base_link,
                        per_page: page_size,
                        page:,
                        groups:,
                        current_user:)
  end
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 2 }
  let(:actual_count) { 3 }
  let(:collection_inner_type) { "Notification" }
  let(:groups) { nil }

  include API::V3::Utilities::PathHelper

  before do
    allow(API::V3::Notifications::NotificationEagerLoadingWrapper)
      .to receive(:wrap)
            .with(notifications)
            .and_return(notifications)
  end

  describe "generation" do
    subject(:collection) { representer.to_json }

    it_behaves_like "offset-paginated APIv3 collection", 3, "notifications", "Notification"

    context "when passing groups" do
      let(:groups) do
        [
          { value: "mentioned", count: 34 },
          { value: "involved", count: 5 }
        ]
      end

      it "renders the groups object as json" do
        expect(subject).to be_json_eql(groups.to_json).at_path("groups")
      end
    end

    describe "detailsSchema" do
      context "when no date alert notifications are present" do
        it "does not renders the detailsSchemas" do
          expect(subject).not_to have_json_path("_embedded/detailsSchemas")
        end
      end

      shared_examples_for "rendering detailsSchemas" do |reasons: [], expected_schemas: reasons|
        before do
          reasons.each_with_index do |reason, idx|
            notifications[idx].reason = reason
          end
        end

        it "renders the required detailsSchemas" do
          properties = expected_schemas.map do |reason|
            API::V3::Notifications::PropertyFactory::PROPERTY_FOR_REASON[reason.to_sym]
          end
          details_schemas = API::V3::Values::Schemas::ValueSchemaFactory.all_for(properties)
          expect(subject).to be_json_eql(details_schemas.to_json).at_path("_embedded/detailsSchemas")
        end
      end

      context "when a start date notification is present" do
        it_behaves_like "rendering detailsSchemas", reasons: ["date_alert_start_date"]
      end

      context "when a due date notification is present" do
        it_behaves_like "rendering detailsSchemas", reasons: ["date_alert_due_date"]
      end

      context "when a due date and a start date notification is present for a milestone work package" do
        let(:notification_list) { build_stubbed_list(:notification, 3, :for_milestone) }

        it_behaves_like "rendering detailsSchemas",
                        reasons: ["date_alert_due_date", "date_alert_start_date"],
                        expected_schemas: ["date_alert_date"]
      end

      context "when both date alert notifications are present" do
        it_behaves_like "rendering detailsSchemas", reasons: ["date_alert_start_date", "date_alert_due_date"]
      end

      context "when a list of mixed date alerts are present" do
        let(:notification_list) do
          [
            build_stubbed(:notification, :for_milestone, reason: "date_alert_start_date"),
            build_stubbed(:notification, reason: "date_alert_start_date"),
            build_stubbed(:notification, :for_milestone, reason: "date_alert_due_date"),
            build_stubbed(:notification, reason: "date_alert_due_date")
          ]
        end

        it_behaves_like "rendering detailsSchemas",
                        expected_schemas: [
                          "date_alert_date",
                          "date_alert_start_date",
                          "date_alert_due_date"
                        ]
      end
    end
  end
end
