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

RSpec.describe Queries::TimeEntries::TimeEntryQuery do
  let(:user) { build_stubbed(:user) }
  let(:base_scope) { TimeEntry.not_ongoing.visible(user).order(id: :desc) }
  let(:instance) { described_class.new }

  before do
    login_as(user)
  end

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all the time entries" do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context "with a user filter" do
    let(:values) { ["1"] }

    before do
      allow(Principal)
        .to receive_message_chain(:in_visible_project, :pluck)
        .with(:id)
        .and_return([1])
    end

    subject do
      instance.where("user_id", "=", values)
      instance
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                   .where(["time_entries.user_id IN (?)", values])

        expect(subject.results.to_sql).to eql expected.to_sql
      end

      context "with a me value" do
        let(:values) { ["me"] }

        it "replaces the value to produce the query" do
          expected = base_scope
                     .where(["time_entries.user_id IN (?)", [user.id.to_s]])

          expect(subject.results.to_sql).to eql expected.to_sql
        end
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(subject).to be_valid
      end

      context "with a me value and being logged in" do
        let(:values) { ["me"] }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "with not existing values" do
        let(:values) { [""] }

        it "is invalid" do
          expect(subject).to be_invalid
        end
      end
    end
  end

  context "with a project filter" do
    before do
      allow(Project)
        .to receive_message_chain(:visible, :pluck)
        .with(:id)
        .and_return([1])
      instance.where("project_id", "=", ["1"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                   .where(["time_entries.project_id IN (?)", ["1"]])

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("project_id", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with a work_package filter" do
    before do
      allow(WorkPackage)
        .to receive_message_chain(:visible, :pluck)
        .with(:id)
        .and_return([1])
      instance.where("work_package_id", "=", ["1"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                   .where(["time_entries.work_package_id IN (?)", ["1"]])

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("work_package_id", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end

  context "with an order by id asc" do
    describe "#results" do
      it "returns all visible time entries ordered by id asc" do
        expect(instance.order(id: :asc).results.to_sql)
          .to eql base_scope.except(:order).order(id: :asc).to_sql
      end
    end
  end
end
