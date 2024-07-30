# --copyright
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
# ++

require "spec_helper"

RSpec.describe API::V3::Notifications::PropertyFactory do
  let(:traits) { [] }
  let(:resource) { build_stubbed(:work_package, *traits) }

  let(:notification) do
    build_stubbed(:notification,
                  resource:,
                  reason:)
  end

  describe ".details_for" do
    context "for a date_alert_start_date notification" do
      let(:reason) { :date_alert_start_date }

      it "returns one detail" do
        expect(described_class.details_for(notification).size)
          .to eq 1
      end

      it "returns an array of `Values::Property` representers" do
        expect(described_class.details_for(notification)[0])
          .to be_a API::V3::Values::PropertyDateRepresenter
      end

      it "sets the represented property to :start_date" do
        represented = described_class.details_for(notification)[0].represented
        expect(represented)
          .to be_a API::V3::Values::PropertyModel
        expect(represented.property)
          .to eq :start_date
      end
    end

    context "for a date_alert_due_date notification" do
      let(:reason) { :date_alert_due_date }

      it "returns one detail" do
        expect(described_class.details_for(notification).size)
          .to eq 1
      end

      it "returns an array of `Values::Property` representers" do
        expect(described_class.details_for(notification)[0])
          .to be_a API::V3::Values::PropertyDateRepresenter
      end

      it "sets the represented property to :due_date" do
        represented = described_class.details_for(notification)[0].represented
        expect(represented)
          .to be_a API::V3::Values::PropertyModel
        expect(represented.property)
          .to eq :due_date
      end
    end

    context "for a date_alert_due_date notification with milestone work package" do
      let(:traits) { [:is_milestone] }
      let(:reason) { :date_alert_due_date }

      it "returns one detail" do
        expect(described_class.details_for(notification).size)
          .to eq 1
      end

      it "returns an array of `Values::Property` representers" do
        expect(described_class.details_for(notification)[0])
          .to be_a API::V3::Values::PropertyDateRepresenter
      end

      it "sets the representer property to :date" do
        represented = described_class.details_for(notification)[0].represented
        expect(represented)
          .to be_a API::V3::Values::PropertyModel
        expect(represented.property)
          .to eq :date
      end
    end

    (Notification::REASONS.keys - %i[date_alert_start_date date_alert_due_date]).each do |possible_reason|
      context "for a #{possible_reason} notification" do
        let(:reason) { possible_reason }

        it "is an empty array" do
          expect(described_class.details_for(notification))
            .to eq []
        end
      end
    end
  end

  describe ".schemas_for" do
    context "for a date_alert_start_date notification" do
      let(:reason) { :date_alert_start_date }

      it "returns one detail for the same type" do
        expect(described_class.schemas_for([notification, notification]).size)
          .to eq 1
      end

      it "returns an array of `Values::Schemas::PropertySchemaRepresenter` representers" do
        expect(described_class.schemas_for([notification])[0])
          .to be_a API::V3::Values::Schemas::PropertySchemaRepresenter
      end

      it "returns `Values::Schemas::Model` representer for Start Date" do
        representer = described_class.schemas_for([notification])[0].represented
        expect(representer)
          .to be_a API::V3::Values::Schemas::Model
        expect(representer.name)
          .to eq "Start date"
      end
    end

    context "for a date_alert_due_date notification" do
      let(:reason) { :date_alert_due_date }

      it "returns one detail for the same type" do
        expect(described_class.schemas_for([notification, notification]).size)
          .to eq 1
      end

      it "returns an array of `Values::Schemas::PropertySchemaRepresenter` representers" do
        expect(described_class.schemas_for([notification])[0])
          .to be_a API::V3::Values::Schemas::PropertySchemaRepresenter
      end

      it "returns `Values::Schemas::Model` representer for Finish date" do
        representer = described_class.schemas_for([notification])[0].represented
        expect(representer)
          .to be_a API::V3::Values::Schemas::Model
        expect(representer.name)
          .to eq "Finish date"
      end
    end

    context "for a date_alert_due_date notification with milestone work package" do
      let(:traits) { [:is_milestone] }
      let(:reason) { :date_alert_due_date }

      it "returns one detail for the same type" do
        expect(described_class.schemas_for([notification, notification]).size)
          .to eq 1
      end

      it "returns an array of `Values::Schemas::PropertySchemaRepresenter` representers" do
        expect(described_class.schemas_for([notification])[0])
          .to be_a API::V3::Values::Schemas::PropertySchemaRepresenter
      end

      it "returns `Values::Schemas::Model` representer for Date" do
        representer = described_class.schemas_for([notification])[0].represented
        expect(representer)
          .to be_a API::V3::Values::Schemas::Model
        expect(representer.name)
          .to eq "Date"
      end
    end

    context "for multiple notifications" do
      let(:reason) { :date_alert_due_date }
      let(:reason_start) { :date_alert_start_date }

      let(:notification_start_date) do
        build_stubbed(:notification,
                      resource:,
                      reason: reason_start)
      end

      let(:notification_due_date_milestone) do
        build_stubbed(:notification, :for_milestone, reason:)
      end

      let(:notification_start_date_milestone) do
        build_stubbed(:notification, :for_milestone, reason: reason_start)
      end

      let(:notifications) do
        [
          notification,
          notification_start_date,
          notification_due_date_milestone,
          notification_start_date_milestone
        ]
      end

      it "returns two details for different types" do
        expect(described_class.schemas_for(notifications).size)
          .to eq 3
      end

      it "returns an array of `Values::Schemas::PropertySchemaRepresenter` representers" do
        expect(described_class.schemas_for(notifications))
          .to all be_a API::V3::Values::Schemas::PropertySchemaRepresenter
      end

      it "returns `Values::Schemas::Model` representer for Finish date" do
        representers = described_class.schemas_for(notifications).map(&:represented)
        expect(representers)
          .to all be_a API::V3::Values::Schemas::Model
        expect(representers.first.name)
          .to eq "Finish date"
        expect(representers.second.name)
          .to eq "Start date"
        expect(representers.third.name)
          .to eq "Date"
      end
    end

    (Notification::REASONS.keys - %i[date_alert_start_date date_alert_due_date]).each do |possible_reason|
      context "for a #{possible_reason} notification" do
        let(:reason) { possible_reason }

        it "is an empty array" do
          expect(described_class.schemas_for([notification]))
            .to eq []
        end
      end
    end
  end

  describe ".groups_for" do
    context "with a date_alert_start_date notification" do
      let(:group_values) { { "date_alert_start_date" => 1 } }

      it "returns as a date alert" do
        expect(described_class.groups_for(group_values))
          .to eq({ "dateAlert" => 1 })
      end
    end

    context "for a date_alert_due_date notification" do
      let(:group_values) { { "date_alert_due_date" => 1 } }

      it "returns as a date alert" do
        expect(described_class.groups_for(group_values))
          .to eq({ "dateAlert" => 1 })
      end
    end

    context "for multiple notifications" do
      let(:group_values) { { "mentioned" => 1, "date_alert_due_date" => 2, "date_alert_start_date" => 1 } }

      it "sums up date alerts" do
        expect(described_class.groups_for(group_values))
          .to eq({ "mentioned" => 1, "dateAlert" => 3 })
      end
    end

    (Notification::REASONS.keys - %i[date_alert_start_date date_alert_due_date]).each do |possible_reason|
      context "for a #{possible_reason} notification" do
        let(:group_values) { { possible_reason => 1 } }

        it "returns the unaltered reasons" do
          expect(described_class.groups_for(group_values))
            .to eq group_values
        end
      end
    end
  end
end
