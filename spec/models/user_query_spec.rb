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

RSpec.describe UserQuery do
  # The query default scope filters to users visible to the current user.
  # Admins satisfy `view_all_principals`, so `User.user.visible(admin)` is a no-op,
  # keeping the SQL identical to the hand-written expectations.
  current_user { create(:admin) }

  let(:instance) { described_class.new(name: "Users") }
  let(:base_scope) { User.user.order(id: :desc) }

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all the users" do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context "with a name filter" do
    before do
      instance.where("name", "~", ["a user"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                     .user
                     .where(["unaccent(LOWER(CONCAT(users.firstname, ' ', users.lastname))) LIKE unaccent(?)",
                             "%a user%"])

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("name", "=", [""])
        expect(instance).not_to be_valid
      end
    end
  end

  context "with a status filter" do
    before do
      instance.where("status", "=", ["active"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope.user.where("users.status IN (1)")

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("status", "=", [""])
        expect(instance).not_to be_valid
      end
    end
  end

  context "with a group filter" do
    let(:group_1) { build_stubbed(:group) }

    before do
      allow(Group)
        .to receive_messages(exists?: true, all: [group_1])

      instance.where("group", "=", [group_1.id])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                   .user
                   .where(["users.id IN (#{User.in_group([group_1.id.to_s]).select(:id).to_sql})"])

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("group", "=", [""])
        expect(instance).not_to be_valid
      end
    end
  end

  context "with a non existent filter" do
    before do
      instance.where("not_supposed_to_exist", "=", ["bogus"])
    end

    describe "#results" do
      it "returns a query not returning anything" do
        expected = User.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
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
      it "is the same as handwriting the query" do
        expected = User.user.order(id: :asc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with a name sortation" do
    before do
      instance.order(name: :desc)
    end

    describe "#results", with_settings: { user_format: :firstname_lastname } do
      let(:order_sql) do
        <<~SQL.squish
          CASE
          WHEN users.type = 'User' THEN LOWER(concat_ws(' ', users.firstname, users.lastname))
          WHEN users.type != 'User' THEN LOWER(users.lastname)
          END DESC
        SQL
      end

      it "is the same as handwriting the query" do
        expected = User
            .user
            .order(Arel.sql(order_sql))
            .order(id: :desc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with a group sortation" do
    before do
      instance.order(group: :desc)
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = User.user.joins(:groups).order("groups_users.lastname DESC").order(id: :desc)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with a non existing sortation" do
    # this is a field protected from sortation
    before do
      instance.order(password: :desc)
    end

    describe "#results" do
      it "returns a query not returning anything" do
        expected = User.where(Arel::Nodes::Equality.new(1, 0))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "valid?" do
      it "is false" do
        expect(instance).not_to be_valid
      end
    end
  end

  describe "persistence" do
    it "saves successfully with just a name" do
      uq = described_class.create!(name: "Named")
      expect(uq.reload.name).to eq("Named")
    end

    it "stores the subclass name in the type column" do
      uq = described_class.create!(name: "Named")
      expect(uq.reload.type).to eq("UserQuery")
      expect(PersistedQuery.find(uq.id)).to be_a(described_class)
    end

    it "round-trips filters through serialization" do
      uq = described_class.new(name: "With filter")
      uq.where("status", "=", ["active"])
      uq.save!

      reloaded = described_class.find(uq.id)
      expect(reloaded.filters.size).to eq(1)
      expect(reloaded.filters.first).to be_a(Queries::Users::Filters::StatusFilter)
      expect(reloaded.filters.first.values).to eq(["active"])
    end

    it "round-trips orders through serialization" do
      uq = described_class.new(name: "With order")
      uq.order(name: :desc)
      uq.save!

      reloaded = described_class.find(uq.id)
      expect(reloaded.orders.size).to eq(1)
      expect(reloaded.orders.first).to be_a(Queries::Users::Orders::NameOrder)
      expect(reloaded.orders.first.direction).to eq(:desc)
    end
  end

  describe "registration" do
    it "registers filters as a side-effect of loading the class" do
      expect(Queries::Register.filters[described_class]).to include(
        Queries::Users::Filters::NameFilter,
        Queries::Users::Filters::StatusFilter,
        Queries::Users::Filters::GroupFilter
      )
    end

    it "registers orders as a side-effect of loading the class" do
      expect(Queries::Register.orders[described_class]).to include(
        Queries::Users::Orders::DefaultOrder,
        Queries::Users::Orders::NameOrder,
        Queries::Users::Orders::GroupOrder
      )
    end
  end
end
