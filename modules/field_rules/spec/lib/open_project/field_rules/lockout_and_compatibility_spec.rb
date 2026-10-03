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

RSpec.describe "Field rules: user lock-out and compatibility" do # rubocop:disable RSpec/DescribeClass
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:project) { create(:project, types: [bug]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  def assign_rules(rules, to_project: project, type: bug)
    rule_set = create(:field_rule_set, rule_attributes: rules)
    ProjectFieldRuleScheme.create!(project: to_project,
                                   scheme: create(:field_rule_scheme, mapping: { type => rule_set }))
    FieldRules::Resolver.reset_cache
    rule_set
  end

  def create_contract(attributes = {}, creator: user)
    work_package = build(:work_package, { project:, type: bug, author: user, status:, priority:,
                                          description: nil }.merge(attributes))
    WorkPackages::CreateContract.new(work_package, creator).tap(&:validate)
  end

  def create_with_service(attributes = {})
    work_package = WorkPackage.new
    result = WorkPackages::SetAttributesService
               .new(user:, model: work_package, contract_class: WorkPackages::CreateContract)
               .call({ project:, type: bug, subject: "x" }.merge(attributes))
    [work_package, result]
  end

  def error_symbols(contract, attribute)
    contract.errors.symbols_for(attribute) + contract.errors.symbols_for(:"#{attribute}_id")
  end

  def update_contract(work_package, updater: user)
    WorkPackages::UpdateContract.new(work_package, updater).tap(&:validate)
  end

  describe "rule combinations that must not make creation impossible" do
    it "creates a work package when a required read-only field has a default" do
      assign_rules([{ field_key: "description", required: true, read_only: true, default_value: "Template" }])

      work_package, result = create_with_service

      expect(work_package.description).to eq "Template"
      expect(result.errors.symbols_for(:description)).to be_empty
    end

    it "can still be created once a required field is filled" do
      assign_rules([{ field_key: "category", required: true }])
      category = create(:category, project:)

      expect(error_symbols(create_contract(category: nil), :category)).to include(:required_by_field_rules)
      expect(error_symbols(create_contract(category:), :category)).to be_empty
    end
  end

  describe "required fields the project cannot provide" do
    it "does not require a category in a project that has no category" do
      assign_rules([{ field_key: "category", required: true }])
      expect(project.categories).to be_empty

      expect(error_symbols(create_contract, :category)).not_to include(:required_by_field_rules)
    end
  end

  describe "rules that contradict the native configuration" do
    it "does not hide a custom field that the custom field itself requires" do
      custom_field = create(:string_wp_custom_field, is_for_all: true, is_required: true, types: [bug])
      assign_rules([{ field_key: "custom_field_#{custom_field.id}", hidden: true }])

      expect(create_contract.errors.symbols_for(:"custom_field_#{custom_field.id}")).to be_empty
    end
  end

  describe "defaults that stopped being valid" do
    it "does not block creation when the hidden default priority was deactivated" do
      high = create(:issue_priority, name: "High")
      assign_rules([{ field_key: "priority", hidden: true, default_value: high.id.to_s }])
      high.update_columns(active: false)

      _work_package, result = create_with_service

      expect(result.errors.symbols_for(:priority_id)).to be_empty
    end

    it "does not block creation when the read-only default assignee is not assignable in the project" do
      outsider = create(:user)
      assign_rules([{ field_key: "assignee", read_only: true, default_value: outsider.id.to_s }])

      _work_package, result = create_with_service

      expect(result.errors.symbols_for(:assigned_to)).to be_empty
    end

    it "does not block creation when the default category belongs to another project" do
      foreign = create(:category, project: create(:project))
      assign_rules([{ field_key: "category", hidden: true, default_value: foreign.id.to_s }])

      _work_package, result = create_with_service

      expect(result.errors.symbols_for(:category)).to be_empty
    end

    it "does not block creation when the default category was deleted" do
      category = create(:category, project:)
      assign_rules([{ field_key: "category", hidden: true, default_value: category.id.to_s }])
      category.destroy

      _work_package, result = create_with_service

      expect(result.errors.symbols_for(:category)).to be_empty
    end

    it "still applies the other defaults when one default points at a deleted custom field" do
      custom_field = create(:string_wp_custom_field, is_for_all: true, types: [bug])
      assign_rules([{ field_key: "custom_field_#{custom_field.id}", default_value: "abc" },
                    { field_key: "description", default_value: "Template" }])
      custom_field.destroy
      FieldRules::Resolver.reset_cache

      work_package, _result = create_with_service

      expect(work_package.description).to eq "Template"
    end
  end

  describe "fail-open inside the contract and the service" do
    before { assign_rules([{ field_key: "description", required: true }, { field_key: "priority", hidden: true }]) }

    it "validates without raising when the required check fails" do
      allow(FieldRules::Validator).to receive(:violations).and_raise(StandardError, "boom")

      contract = nil
      expect { contract = create_contract }.not_to raise_error
      expect(contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end

    it "keeps the defaults of a failed rule application out of the way" do
      allow(FieldRules::Resolver).to receive(:for).and_raise(StandardError, "boom")

      expect { create_with_service }.not_to raise_error
    end
  end

  describe "system and dependent updates" do
    before do
      assign_rules([{ field_key: "description", required: true, enforce_on_update: true },
                    { field_key: "estimated_time", read_only: true }])
    end

    it "does not apply any rule for the system user" do
      work_package = build(:work_package, project:, type: bug, author: user, status:, description: nil)

      expect(FieldRules::Validator.violations(work_package, user: User.system)).to be_empty
      expect(WorkPackages::CreateContract.new(work_package, User.system).writable_attributes).to include("estimated_hours")
    end

    it "does not validate dependents that scheduling or ancestors update, even with enforce on update" do
      work_package = create(:work_package, project:, type: bug, author: user, status:, description: nil)
      work_package.subject = "Moved by scheduling"

      contract = WorkPackages::UpdateDependentContract.new(work_package, user)

      expect(contract.validate).to be true
      expect(contract.errors).to be_empty
    end

    it "still enforces the rule for the work package a user edits directly" do
      work_package = create(:work_package, project:, type: bug, author: user, status:, description: nil)
      work_package.subject = "Edited by a user"

      expect(update_contract(work_package).errors.symbols_for(:description)).to include(:required_by_field_rules)
    end
  end

  describe "copying" do
    before { assign_rules([{ field_key: "estimated_time", read_only: true }, { field_key: "priority", hidden: true }]) }

    it "keeps hidden and read-only values when a whole project is copied" do
      work_package = create(:work_package, project:, type: bug, author: user, status:, priority:)

      writable = WorkPackages::CopyProjectContract.new(work_package, user).writable_attributes

      expect(writable).to include("estimated_hours", "priority_id")
    end

    it "does apply the rules to a copy made by a user into a project that has them" do
      work_package = create(:work_package, project:, type: bug, author: user, status:, priority:)

      writable = WorkPackages::CopyContract.new(work_package, user).writable_attributes

      expect(writable).not_to include("estimated_hours", "priority_id")
    end
  end

  describe "grandfathering of existing work packages" do
    let!(:custom_field) { create(:string_wp_custom_field, is_for_all: true, types: [bug]) }
    let(:key) { "custom_field_#{custom_field.id}" }
    let!(:legacy) { create(:work_package, project:, type: bug, author: user, status:, description: nil) }

    before { assign_rules([{ field_key: key, required: true }, { field_key: "description", required: true }]) }

    it "lets users edit unrelated fields of a legacy work package with empty required fields" do
      legacy.subject = "Only the subject changes"
      errors = update_contract(legacy).errors

      expect(errors.symbols_for(:description)).to be_empty
      expect(errors.symbols_for(key.to_sym)).to be_empty
    end

    it "blocks emptying a required custom field" do
      legacy.public_send(:"#{key}=", "filled")
      legacy.save!(validate: false)
      stored = WorkPackage.find(legacy.id)
      stored.public_send(:"#{key}=", "")

      expect(update_contract(stored).errors.symbols_for(key.to_sym)).to include(:required_by_field_rules)
    end

    it "checks the rules of the target project when the work package is moved" do
      target = create(:project, types: [bug])
      assign_rules([{ field_key: "description", required: true }], to_project: target)
      legacy.project = target

      expect(update_contract(legacy).errors.symbols_for(:description)).to include(:required_by_field_rules)
    end

    it "keeps hidden values and does not report them as changed" do
      other = create(:project, types: [bug])
      assign_rules([{ field_key: "priority", hidden: true }], to_project: other)
      work_package = create(:work_package, project: other, type: bug, author: user, status:, priority:)
      work_package.subject = "Renamed"

      expect(update_contract(work_package).errors.symbols_for(:priority_id)).to be_empty
      expect(work_package.reload.priority).to eq priority
    end
  end
end
