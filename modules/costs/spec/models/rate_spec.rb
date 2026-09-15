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

require_relative "../spec_helper"

RSpec.describe Rate do
  let(:rate) { build(:rate) }

  describe "#valid?" do
    describe "WHEN no rate is supplied" do
      before do
        rate.rate = nil
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:rate]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN no number is supplied" do
      before do
        rate.rate = "test"
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:rate]).to eq([I18n.t("activerecord.errors.messages.not_a_number")])
      end
    end

    describe "WHEN a rate is supplied" do
      before do
        rate.rate = 5.0
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a date is supplied" do
      before do
        rate.valid_from = Date.today
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a transformable string is supplied for date" do
      before do
        rate.valid_from = "2012-03-04"
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN a nontransformable string is supplied for date" do
      before do
        rate.valid_from = "2012-02-30"
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:valid_from]).to eq([I18n.t("activerecord.errors.messages.not_a_date")])
      end
    end

    describe "WHEN no value is supplied for date" do
      before do
        rate.valid_from = nil
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors[:valid_from]).to eq([I18n.t("activerecord.errors.messages.not_a_date")])
      end
    end

    describe "WHEN the principal is a placeholder user" do
      before do
        rate.principal = build(:placeholder_user)
      end

      it { expect(rate).to be_valid }
    end

    describe "WHEN the principal is a group" do
      before do
        rate.principal = build(:group)
      end

      it "is not valid" do
        expect(rate).not_to be_valid
        expect(rate.errors.symbols_for(:principal)).to include(:invalid)
      end
    end
  end

  describe "#principal" do
    it "is reachable under the deprecated user alias" do
      user = build(:user)
      rate.user = user

      expect(rate.principal).to eq(user)
      expect(rate.user).to eq(user)
    end

    # The rate outlives the principal so already booked costs stay explainable.
    it "falls back to the deleted user when the principal no longer exists" do
      DeletedUser.first
      rate.principal = nil
      rate.user_id = 0

      expect(rate.principal).to be_a(DeletedUser)
    end
  end

  # Behavioural coverage for the entry lookups the rate callbacks drive. Written
  # against the returned entries only, so it holds regardless of how the queries
  # are built.
  describe Rate::Methods do
    shared_let(:rated_user) { create(:user) }
    shared_let(:other_user) { create(:user) }
    shared_let(:parent_project) { create(:project) }
    shared_let(:child_project) { create(:project, parent: parent_project) }
    shared_let(:unrelated_project) { create(:project) }

    shared_let(:hourly_rate) do
      create(:hourly_rate, user: rated_user, project: parent_project, valid_from: 3.years.ago, rate: 10)
    end
    shared_let(:default_rate) do
      create(:default_hourly_rate, user: rated_user, valid_from: 3.years.ago, rate: 5)
    end

    subject(:methods) { described_class.new(hourly_rate) }

    # TimeEntry recosts itself on save, so the rate under test is written
    # afterwards to pin the exact state these lookups are meant to find.
    def entry_in(project, spent_on:, rate: nil, user: rated_user)
      work_package = create(:work_package, project:)
      entry = create(:time_entry, project:, entity: work_package, user:, spent_on:)
      entry.update_column(:rate_id, rate&.id)
      entry
    end

    describe "#child_entries" do
      it "returns entries in descendant projects costed with this rate" do
        entry = entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(methods.child_entries(Date.new(2026, 6, 1))).to contain_exactly(entry)
      end

      it "excludes entries in the rate's own project" do
        entry_in(parent_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(methods.child_entries(Date.new(2026, 6, 1))).to be_empty
      end

      it "excludes entries of another user and of unrelated projects" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate, user: other_user)
        entry_in(unrelated_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(methods.child_entries(Date.new(2026, 6, 1))).to be_empty
      end

      it "excludes entries costed with a different rate" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: default_rate)

        expect(methods.child_entries(Date.new(2026, 6, 1))).to be_empty
      end

      it "takes everything from the given date onwards when only one is given" do
        before_date = entry_in(child_project, spent_on: Date.new(2026, 5, 31), rate: hourly_rate)
        on_date = entry_in(child_project, spent_on: Date.new(2026, 6, 1), rate: hourly_rate)
        later = entry_in(child_project, spent_on: Date.new(2027, 1, 1), rate: hourly_rate)

        found = methods.child_entries(Date.new(2026, 6, 1))

        expect(found).to contain_exactly(on_date, later)
        expect(found).not_to include(before_date)
      end

      it "includes both ends of a given range" do
        from = entry_in(child_project, spent_on: Date.new(2026, 6, 1), rate: hourly_rate)
        to = entry_in(child_project, spent_on: Date.new(2026, 6, 30), rate: hourly_rate)
        outside = entry_in(child_project, spent_on: Date.new(2026, 7, 1), rate: hourly_rate)

        found = methods.child_entries(Date.new(2026, 6, 1), Date.new(2026, 6, 30))

        expect(found).to contain_exactly(from, to)
        expect(found).not_to include(outside)
      end

      it "orders the given dates" do
        entry = entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(methods.child_entries(Date.new(2026, 6, 30), Date.new(2026, 6, 1))).to contain_exactly(entry)
      end

      it "is empty for a rate that is not an hourly rate" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(described_class.new(default_rate).child_entries(Date.new(2026, 6, 1))).to eq([])
      end
    end

    describe "#orphaned_child_entries" do
      it "returns entries in descendant projects without any rate" do
        entry = entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: nil)

        expect(methods.orphaned_child_entries(Date.new(2026, 6, 1))).to contain_exactly(entry)
      end

      it "returns entries costed with a default rate" do
        entry = entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: default_rate)

        expect(methods.orphaned_child_entries(Date.new(2026, 6, 1))).to contain_exactly(entry)
      end

      it "excludes entries already costed with a project rate" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: hourly_rate)

        expect(methods.orphaned_child_entries(Date.new(2026, 6, 1))).to be_empty
      end

      it "excludes entries of another user and of unrelated projects" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: nil, user: other_user)
        entry_in(unrelated_project, spent_on: Date.new(2026, 6, 10), rate: nil)

        expect(methods.orphaned_child_entries(Date.new(2026, 6, 1))).to be_empty
      end

      it "includes both ends of a given range" do
        from = entry_in(child_project, spent_on: Date.new(2026, 6, 1), rate: nil)
        to = entry_in(child_project, spent_on: Date.new(2026, 6, 30), rate: nil)
        outside = entry_in(child_project, spent_on: Date.new(2026, 7, 1), rate: nil)

        found = methods.orphaned_child_entries(Date.new(2026, 6, 1), Date.new(2026, 6, 30))

        expect(found).to contain_exactly(from, to)
        expect(found).not_to include(outside)
      end

      it "is empty for a rate that is not an hourly rate" do
        entry_in(child_project, spent_on: Date.new(2026, 6, 10), rate: nil)

        expect(described_class.new(default_rate).orphaned_child_entries(Date.new(2026, 6, 1))).to eq([])
      end
    end
  end

  describe "#placeholder_rate?" do
    it "is true only for a placeholder user" do
      expect(build(:rate, principal: build(:placeholder_user))).to be_placeholder_rate
      expect(build(:rate, principal: build(:user))).not_to be_placeholder_rate
    end
  end
end
