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

RSpec.describe ResourceAllocation do
  describe "associations" do
    it "belongs to a polymorphic entity" do
      association = described_class.reflect_on_association(:entity)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:polymorphic]).to be(true)
    end

    it "belongs to a principal (user), optional" do
      association = described_class.reflect_on_association(:principal)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq("User")
      expect(association.options[:optional]).to be(true)
    end
  end

  describe "state enum" do
    it "exposes the four allowed string-backed states" do
      expect(described_class.states).to eq(
        "requested" => "requested",
        "allocated" => "allocated",
        "rejected" => "rejected",
        "canceled" => "canceled"
      )
    end

    it "rejects unknown state values" do
      expect { described_class.new(state: "unknown") }.to raise_error(ArgumentError)
    end

    it "exposes a factory trait per state value" do
      described_class.states.each_key do |value|
        expect(build(:resource_allocation, value.to_sym).state).to eq(value)
      end
    end
  end

  describe "validations" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:planner) { create(:resource_planner, project:, principal: owner) }

    let(:allocation) { build(:resource_allocation, entity: planner, principal: owner) }

    it "is valid with the factory defaults" do
      expect(allocation).to be_valid
    end

    describe "presence" do
      it "requires entity" do
        allocation.entity = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:entity]).to be_present
      end

      it "requires state" do
        allocation.state = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:state]).to be_present
      end

      it "requires start_date" do
        allocation.start_date = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:start_date]).to be_present
      end

      it "requires end_date" do
        allocation.end_date = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:end_date]).to be_present
      end

      it "requires allocated_time" do
        allocation.allocated_time = nil
        expect(allocation).not_to be_valid
        expect(allocation.errors[:allocated_time]).to be_present
      end

      it "does not require principal (column is nullable)" do
        allocation.principal = nil
        expect(allocation).to be_valid
      end
    end

    describe "allocated_time numericality" do
      it "is invalid when zero" do
        allocation.allocated_time = 0
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:allocated_time)).to include(:greater_than)
      end

      it "is invalid when negative" do
        allocation.allocated_time = -1
        expect(allocation).not_to be_valid
        expect(allocation.errors.symbols_for(:allocated_time)).to include(:greater_than)
      end

      it "is valid when positive" do
        allocation.allocated_time = 1
        expect(allocation).to be_valid
      end
    end

    describe "date range" do
      context "when end_date is after start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 1)
          allocation.end_date = Date.new(2026, 1, 2)
        end

        it "is valid" do
          expect(allocation).to be_valid
        end
      end

      context "when end_date equals start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 1)
          allocation.end_date = Date.new(2026, 1, 1)
        end

        it "is invalid" do
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
        end
      end

      context "when end_date is before start_date" do
        before do
          allocation.start_date = Date.new(2026, 1, 5)
          allocation.end_date = Date.new(2026, 1, 2)
        end

        it "is invalid" do
          expect(allocation).not_to be_valid
          expect(allocation.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
        end
      end
    end
  end

  describe "user_filter serialization" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:planner) { create(:resource_planner, project:, principal: owner) }

    it "serializes filters using the same coder as UserQuery" do
      coder = described_class.type_for_attribute(:user_filter).coder
      user_query_coder = UserQuery.type_for_attribute(:filters).coder

      expect(coder).to be_a(Queries::Serialization::Filters)
      expect(coder.klass).to eq(UserQuery)
      expect(coder.registered_filters).to eq(user_query_coder.registered_filters)
    end

    it "round-trips a UserQuery filter through the database" do
      filter = UserQuery.new.filter_for(:name)
      filter.operator = "~"
      filter.values = ["alice"]

      allocation = create(:resource_allocation, entity: planner, principal: owner, user_filter: [filter])

      reloaded = described_class.find(allocation.id)
      expect(reloaded.user_filter.size).to eq(1)
      expect(reloaded.user_filter.first).to be_a(Queries::Users::Filters::NameFilter)
      expect(reloaded.user_filter.first.operator).to eq("~")
      expect(reloaded.user_filter.first.values).to eq(["alice"])
    end

    it "defaults to an empty array" do
      allocation = create(:resource_allocation, entity: planner, principal: owner)
      expect(allocation.reload.user_filter).to eq([])
    end
  end
end
