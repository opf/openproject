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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Field rules enforcement in work package contracts" do # rubocop:disable RSpec/DescribeClass
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:issue_priority) }
  shared_let(:project) { create(:project, types: [bug, story]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  let(:rules) do
    [{ field_key: "description", required: true },
     { field_key: "priority", hidden: true },
     { field_key: "estimated_time", read_only: true }]
  end
  let(:rule_set) { create(:field_rule_set, rule_attributes: rules) }

  before do
    scheme = create(:field_rule_scheme, mapping: { bug => rule_set })
    ProjectFieldRuleScheme.create!(project:, scheme:)
  end

  def create_contract(**attrs)
    work_package = build(:work_package, { project:, type: bug, author: user, status:, priority: nil }.merge(attrs))
    WorkPackages::CreateContract.new(work_package, user).tap(&:validate)
  end

  describe "required (create)" do
    it "reports a blank required field" do
      contract = create_contract(description: nil)

      expect(contract.errors.symbols_for(:description)).to include(:required_by_field_rules)
    end

    it "accepts a filled required field" do
      contract = create_contract(description: "Steps to reproduce")

      expect(contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end

    it "does not apply to types without a rule" do
      contract = create_contract(type: story, description: nil)

      expect(contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end

    it "does not apply to system updates" do
      work_package = build(:work_package, project:, type: bug, author: user, status:, description: nil)
      contract = WorkPackages::CreateContract.new(work_package, User.system).tap(&:validate)

      expect(contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end
  end

  describe "hidden and read-only (writable attributes)" do
    it "removes restricted attributes from writable attributes" do
      work_package = build(:work_package, project:, type: bug, author: user, status:)
      writable = WorkPackages::CreateContract.new(work_package, user).writable_attributes

      expect(writable).to include("description")
      expect(writable).not_to include("priority_id", "estimated_hours")
    end

    it "rejects user writes to a hidden field" do
      contract = create_contract(description: "x", priority:)

      expect(contract.errors.symbols_for(:priority)).to include(:error_readonly)
    end

    it "keeps hidden and read-only target versions from being assigned" do
      rule_set.rules.create!(field_key: "target_versions", read_only: true)
      FieldRules::Resolver.reset_cache
      work_package = build(:work_package, project:, type: bug, author: user, status:, description: "x")
      work_package.target_version_ids_replacements = [create(:version, project:).id]
      contract = WorkPackages::CreateContract.new(work_package, user).tap(&:validate)

      expect(contract.errors.symbols_for(:target_versions)).to include(:error_readonly)
    end

    it "keeps everything writable for types without rules" do
      work_package = build(:work_package, project:, type: story, author: user, status:)
      writable = WorkPackages::CreateContract.new(work_package, user).writable_attributes

      expect(writable).to include("priority_id", "estimated_hours")
    end
  end

  describe "required assignee" do
    let(:rules) { [{ field_key: "assignee", required: true }] }

    it "reports the violation on the API-facing attribute" do
      contract = create_contract(assigned_to: nil)

      expect(contract.errors.symbols_for(:assigned_to)).to include(:required_by_field_rules)
    end
  end

  describe "required (update, grandfathered)" do
    let!(:work_package) do
      create(:work_package, project:, type: bug, author: user, status:, description: nil)
    end

    def update_contract(work_package)
      WorkPackages::UpdateContract.new(work_package, user).tap(&:validate)
    end

    it "lets users edit other fields on legacy work packages" do
      work_package.subject = "Renamed"

      expect(update_contract(work_package).errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end

    it "blocks clearing a required field" do
      work_package.update_columns(description: "Filled")
      work_package.reload.description = ""

      expect(update_contract(work_package).errors.symbols_for(:description)).to include(:required_by_field_rules)
    end

    it "checks again when the type changes into a type with rules" do
      other = create(:work_package, project:, type: story, author: user, status:, description: nil)
      other.type = bug

      expect(update_contract(other).errors.symbols_for(:description)).to include(:required_by_field_rules)
    end

    it "enforces on every update when the rule asks for it" do
      rule_set.rules.find { |rule| rule.field_key == "description" }.update!(enforce_on_update: true)
      FieldRules::Resolver.reset_cache
      work_package.subject = "Renamed"

      expect(update_contract(work_package).errors.symbols_for(:description)).to include(:required_by_field_rules)
    end
  end

  describe "fail-open" do
    it "falls back to native writable attributes when the resolver raises" do
      allow(FieldRules::Resolver).to receive(:for).and_raise(StandardError, "boom")
      work_package = build(:work_package, project:, type: bug, author: user, status:)

      expect(WorkPackages::CreateContract.new(work_package, user).writable_attributes).to include("priority_id")
    end

    it "passes the patch target guard against the current core" do
      expect { OpenProject::FieldRules.assert_patch_targets! }.not_to raise_error
    end
  end
end
