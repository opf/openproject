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

RSpec.describe ResourcePlanner do
  describe "date range validation" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    let(:planner) { build(:resource_planner, project:, principal: owner, start_date:, end_date:) }

    context "when end_date is after start_date" do
      let(:start_date) { Date.new(2026, 1, 1) }
      let(:end_date) { Date.new(2026, 1, 2) }

      it "is valid" do
        expect(planner).to be_valid
      end
    end

    context "when end_date equals start_date" do
      let(:start_date) { Date.new(2026, 1, 1) }
      let(:end_date) { Date.new(2026, 1, 1) }

      it "is invalid" do
        expect(planner).not_to be_valid
        expect(planner.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
      end

      it "uses the planner-specific translation" do
        planner.valid?
        expect(planner.errors[:end_date]).to include("must be after the start date.")
      end
    end

    context "when end_date is before start_date" do
      let(:start_date) { Date.new(2026, 1, 5) }
      let(:end_date) { Date.new(2026, 1, 2) }

      it "is invalid" do
        expect(planner).not_to be_valid
        expect(planner.errors.symbols_for(:end_date)).to include(:greater_than_start_date)
      end
    end

    context "when start_date is missing" do
      let(:start_date) { nil }
      let(:end_date) { Date.new(2026, 1, 2) }

      it "is valid" do
        expect(planner).to be_valid
      end
    end

    context "when end_date is missing" do
      let(:start_date) { Date.new(2026, 1, 2) }
      let(:end_date) { nil }

      it "is valid" do
        expect(planner).to be_valid
      end
    end

    context "when both dates are missing" do
      let(:start_date) { nil }
      let(:end_date) { nil }

      it "is valid" do
        expect(planner).to be_valid
      end
    end
  end

  describe "#visible?" do
    shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    shared_let(:owner) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:permitted_other) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end
    shared_let(:non_member) { create(:user) }

    let(:planner) { create(:resource_planner, project:, principal: owner, public: planner_public) }

    context "with a private planner" do
      let(:planner_public) { false }

      it "is visible to the owner" do
        expect(planner.visible?(owner)).to be(true)
      end

      it "is not visible to another permitted user" do
        expect(planner.visible?(permitted_other)).to be(false)
      end

      it "is not visible to a non-member" do
        expect(planner.visible?(non_member)).to be(false)
      end
    end

    context "with a public planner" do
      let(:planner_public) { true }

      it "is visible to the owner" do
        expect(planner.visible?(owner)).to be(true)
      end

      it "is visible to any permitted user" do
        expect(planner.visible?(permitted_other)).to be(true)
      end

      it "is not visible to users without view_resource_planners on the project" do
        expect(planner.visible?(non_member)).to be(false)
      end
    end
  end

  describe ".allowed_child_class" do
    it "resolves an allowed child name to its class" do
      expect(described_class.allowed_child_class("ResourceWorkPackageList")).to eq(ResourceWorkPackageList)
      expect(described_class.allowed_child_class("ResourceUserCard")).to eq(ResourceUserCard)
    end

    it "returns nil for a real but disallowed constant" do
      expect(described_class.allowed_child_class("User")).to be_nil
      expect(described_class.allowed_child_class("Kernel")).to be_nil
    end

    it "returns nil for unknown, blank or nil names" do
      expect(described_class.allowed_child_class("DoesNotExist")).to be_nil
      expect(described_class.allowed_child_class("")).to be_nil
      expect(described_class.allowed_child_class(nil)).to be_nil
    end

    it "is scoped per view type: a leaf view allows no children" do
      expect(ResourceWorkPackageList.allowed_child_class("ResourceUserCard")).to be_nil
    end
  end
end
