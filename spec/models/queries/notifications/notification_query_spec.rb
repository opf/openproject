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
#++

require "spec_helper"

RSpec.describe Queries::Notifications::NotificationQuery do
  shared_let(:project) { create(:project) }

  shared_let(:recipient) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:notification) { create(:notification, recipient:, resource: work_package) }

  let(:instance) { described_class.new(user: recipient) }
  let(:base_scope) { Notification.visible(recipient).recipient(recipient) }

  current_user { recipient }

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all the users" do
        expect(instance.results.to_sql).to eql base_scope.order(id: :desc).to_sql
      end
    end
  end

  context "with a read_ian filter" do
    before do
      instance.where("read_ian", "=", ["t"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope.where("notifications.read_ian IN ('t')").order(id: :desc).to_sql

        expect(instance.results.to_sql).to eql expected
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("read_ian", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with a non existent filter" do
    before do
      instance.where("not_supposed_to_exist", "=", ["bogus"])
    end

    describe "#results" do
      it "returns a query not returning anything" do
        expected = Notification.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).to be_invalid
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
      it "is the same as handwriting the query" do
        expected = base_scope.order(id: :asc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with a read_ian sortation" do
    before do
      instance.order(read_ian: :desc)
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope.order(read_ian: :desc, id: :desc).to_sql

        expect(instance.results.to_sql).to eql expected
      end
    end
  end

  context "with a reason sortation" do
    before do
      instance.order(reason: :desc)
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope.order(reason: :desc, id: :desc).to_sql

        expect(instance.results.to_sql).to eql expected
      end
    end
  end

  context "with a non existing sortation" do
    before do
      instance.order(non_existing: :desc)
    end

    describe "#results" do
      it "returns a query not returning anything" do
        expected = Notification.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).to be_invalid
      end
    end
  end

  context "with a reason group_by" do
    before do
      instance.group(:reason)
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                     .group(:reason)
                     .order(reason: :asc)
                     .select(:reason, Arel.sql("COUNT(*)"))
                     .to_sql

        expect(instance.groups.to_sql).to eql expected
      end
    end
  end

  context "with a project group_by" do
    before do
      instance.group(:project)
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                     .joins("JOIN work_packages " \
                            "ON notifications.resource_id = work_packages.id " \
                            "AND notifications.resource_type = 'WorkPackage'")
                     .group(:project_id)
                     .order(project_id: :asc)
                     .select(:project_id, Arel.sql("COUNT(*)"))
                     .to_sql

        expect(instance.groups.to_sql).to eql expected
      end
    end
  end

  context "with a non existing group_by" do
    before do
      instance.group(:does_not_exist)
    end

    describe "#results" do
      it "returns a query not returning anything" do
        expected = Notification.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).to be_invalid
      end
    end
  end
end
