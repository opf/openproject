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

RSpec.describe Queries::Notifications::NotificationQuery, "integration" do
  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:invisible_project) { create(:project) }

  shared_let(:recipient) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages],
             other_project => %i[view_work_packages]
           })
  end
  shared_let(:other_user) { create(:user) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project: other_project) }
  shared_let(:invisible_work_package) { create(:work_package, project: invisible_project) }
  shared_let(:mentioned_notification) { create(:notification, recipient:, project:, resource: work_package) }
  shared_let(:assigned_notification) do
    create(:notification, recipient:, project: other_project, resource: other_work_package, reason: "assigned")
  end
  shared_let(:other_user_notification) { create(:notification, recipient: other_user, project:, resource: work_package) }
  shared_let(:invisible_notification) do
    create(:notification, recipient:, project: invisible_project, resource: invisible_work_package)
  end

  let(:instance) { described_class.new(user: recipient) }

  current_user { recipient }

  context "without a filter" do
    describe "#results" do
      it "returns all the notifications visible to the user" do
        expect(instance.results).to eq [assigned_notification, mentioned_notification]
      end
    end
  end

  context "with a read_ian filter" do
    before do
      mentioned_notification.update_column(:read_ian, true)

      instance.where("read_ian", "=", ["t"])
    end

    describe "#results" do
      it "returns notifications that are read in app" do
        expect(instance.results).to eq [mentioned_notification]
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("read_ian", "=", [""])
        expect(instance).not_to be_valid
      end
    end
  end

  context "with a non existent filter" do
    before do
      instance.where("not_supposed_to_exist", "=", ["bogus"])
    end

    describe "#results" do
      it "returns nothing" do
        expect(instance.results).to be_empty
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).not_to be_valid
      end

      it "returns the error on the filter" do
        instance.valid?

        expect(instance.errors[:filters]).to eql ["Not supposed to exist filter does not exist."]
      end
    end
  end

  context "with an id sortation" do
    before do
      instance.order(id: :asc)
    end

    describe "#results" do
      it "returns all the notifications sorted by id asc" do
        expect(instance.results).to eq [mentioned_notification, assigned_notification]
      end
    end
  end

  context "with a read_ian sortation" do
    before do
      mentioned_notification.update_column(:read_ian, true)

      instance.order(read_ian: :desc)
    end

    describe "#results" do
      it "returns all read in app first and then the other" do
        expect(instance.results).to eq [mentioned_notification, assigned_notification]
      end
    end
  end

  context "with a reason sortation" do
    before do
      instance.order(reason: :asc)
    end

    describe "#results" do
      it "returns the notifications ordered by reason" do
        expect(instance.results).to eq [mentioned_notification, assigned_notification]
      end
    end
  end

  context "with a non existing sortation" do
    before do
      instance.order(non_existing: :desc)
    end

    describe "#results" do
      it "returns nothing" do
        expect(instance.results).to be_empty
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).not_to be_valid
      end
    end
  end

  context "with a reason group_by" do
    let!(:other_mentioned_notification) { create(:notification, recipient:, project:, resource: work_package) }

    before do
      instance.group(:reason)
    end

    describe "#results" do
      it "returns the notifications ordered by reason" do
        expect(instance.results).to eq [other_mentioned_notification, mentioned_notification, assigned_notification]
      end
    end

    describe "#groups" do
      it "returns the counts per reason" do
        expect(instance.groups.map { [_1.reason, _1.count] })
          .to eq [["mentioned", 2], ["assigned", 1]]
      end
    end
  end

  context "with a project group_by" do
    before do
      instance.group(:project)
    end

    describe "#results" do
      it "returns the notifications ordered by project" do
        expect(instance.results).to eq [mentioned_notification, assigned_notification]
      end
    end

    describe "#groups" do
      it "returns the counts per project" do
        expect(instance.groups.map { [_1.project, _1.count] })
          .to eq [[project, 1], [other_project, 1]]
      end
    end
  end

  context "with a non existing group_by" do
    before do
      instance.group(:does_not_exist)
    end

    describe "#results" do
      it "returns nothing" do
        expect(instance.results).to be_empty
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).not_to be_valid
      end
    end
  end
end
