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

RSpec.describe "Field rule invariants" do # rubocop:disable RSpec/DescribeClass
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:project) { create(:project, types: [bug, story]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end

  let(:rule_set) do
    create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true },
                                              { field_key: "priority", hidden: true }])
  end
  let(:other_rule_set) { create(:field_rule_set, rule_attributes: [{ field_key: "estimated_time", read_only: true }]) }
  let(:scheme) { create(:field_rule_scheme, mapping: { bug => rule_set, story => other_rule_set }) }

  def timestamps = { created_at: Time.current, updated_at: Time.current }

  def create_contract(type: bug)
    work_package = build(:work_package, project:, type:, author: user, status:, priority:, description: nil)
    WorkPackages::CreateContract.new(work_package, user).tap(&:validate)
  end

  describe "database constraints" do
    it "rejects the same field twice in one rule set" do
      expect do
        FieldRule.insert_all!([{ rule_set_id: rule_set.id, field_key: "description", position: 9, **timestamps }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects the same type twice in one scheme" do
      scheme

      expect do
        FieldRuleSchemeItem.insert_all!([{ scheme_id: scheme.id, type_id: bug.id, rule_set_id: other_rule_set.id,
                                           **timestamps }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects two schemes for one project" do
      ProjectFieldRuleScheme.create!(project:, scheme:)
      other = create(:field_rule_scheme, mapping: { bug => rule_set })

      expect do
        ProjectFieldRuleScheme.insert_all!([{ project_id: project.id, scheme_id: other.id, **timestamps }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects duplicate names of rule sets and schemes" do
      expect { create(:field_rule_set, name: rule_set.name) }.to raise_error(ActiveRecord::RecordInvalid)
      expect do
        FieldRuleSet.insert_all!([{ name: rule_set.name, active: true, **timestamps }])
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "refuses to delete a rule set that a scheme uses, even with raw SQL" do
      scheme

      expect { FieldRuleSet.where(id: rule_set.id).delete_all }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses to delete a scheme that a project uses, even with raw SQL" do
      ProjectFieldRuleScheme.create!(project:, scheme:)

      expect { FieldRuleScheme.where(id: scheme.id).delete_all }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses to destroy rule sets and schemes through the model" do
      scheme

      expect(rule_set.destroy).to be false
      expect(scheme.destroy).to be false
      expect(FieldRuleSet.exists?(rule_set.id)).to be true
      expect(FieldRuleScheme.exists?(scheme.id)).to be true
    end

    it "removes the project assignment together with the project, and keeps scheme and rule sets" do
      ProjectFieldRuleScheme.create!(project:, scheme:)

      expect { project.destroy }.to change(ProjectFieldRuleScheme, :count).by(-1)
      expect(FieldRuleScheme.exists?(scheme.id)).to be true
      expect(FieldRuleSet.exists?(rule_set.id)).to be true
    end

    it "cascades the rules when an unused rule set row is deleted by SQL" do
      unused = create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true }])

      expect { FieldRuleSet.where(id: unused.id).delete_all }.to change(FieldRule, :count).by(-1)
    end
  end

  describe "when a type is deleted" do
    before do
      ProjectFieldRuleScheme.create!(project:, scheme:)
      FieldRules::Resolver.reset_cache
    end

    it "cascades the scheme item, keeps scheme, rule sets and the other item" do
      expect { bug.destroy }.to change(FieldRuleSchemeItem, :count).by(-1)

      expect(FieldRuleScheme.exists?(scheme.id)).to be true
      expect(FieldRuleSet.exists?(rule_set.id)).to be true
      expect(FieldRuleSchemeItem.where(scheme_id: scheme.id).pluck(:type_id)).to eq [story.id]
    end

    it "keeps resolving the remaining types and gives the deleted type native behaviour" do
      bug.destroy
      FieldRules::Resolver.reset_cache

      expect(FieldRules::Resolver.for(project.id, bug.id)).to be_empty
      expect(FieldRules::Resolver.for(project.id, story.id).read_only?("estimated_time")).to be true
    end
  end

  describe "deactivation while in use" do
    before do
      ProjectFieldRuleScheme.create!(project:, scheme:)
      FieldRules::Resolver.reset_cache
    end

    it "stops enforcing a deactivated rule set and enforces it again after activation" do
      expect(create_contract.errors.symbols_for(:description)).to include(:required_by_field_rules)

      FieldRules::RuleSetService.deactivate(rule_set)
      expect(create_contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)

      FieldRules::RuleSetService.activate(rule_set.reload)
      expect(create_contract.errors.symbols_for(:description)).to include(:required_by_field_rules)
    end

    it "keeps the assignment of a deactivated scheme and stops enforcing it" do
      FieldRules::SchemeService.deactivate(scheme)

      expect(ProjectFieldRuleScheme.where(project_id: project.id, scheme_id: scheme.id)).to exist
      expect(FieldRules::Resolver.for(project.id, bug.id)).to be_empty
      expect(create_contract.errors.symbols_for(:description)).not_to include(:required_by_field_rules)
    end

    it "refuses to assign an inactive scheme but does not break the existing assignment when it turns inactive" do
      scheme.update_columns(active: false)
      FieldRules::Resolver.reset_cache

      expect(FieldRules::SchemeService.assign(project, scheme).success?).to be false
      expect(FieldRules::Resolver.for(project.id, bug.id)).to be_empty
    end

    it "treats a rule set deactivated by raw SQL like a deactivated one" do
      rule_set.update_columns(active: false)
      FieldRules::Resolver.reset_cache

      expect(FieldRules::Resolver.for(project.id, bug.id)).to be_empty
    end
  end

  describe "rules that point at a deleted or unavailable custom field" do
    let!(:custom_field) { create(:string_wp_custom_field, is_for_all: true, types: [bug]) }
    let(:key) { "custom_field_#{custom_field.id}" }

    before do
      rules = create(:field_rule_set, rule_attributes: [{ field_key: key, required: true }])
      ProjectFieldRuleScheme.create!(project:, scheme: create(:field_rule_scheme, mapping: { bug => rules }))
    end

    it "enforces the rule while the custom field is active" do
      expect(create_contract.errors.symbols_for(:"custom_field_#{custom_field.id}")).to include(:required_by_field_rules)
    end

    it "keeps creating work packages after the custom field was deleted" do
      custom_field.destroy
      FieldRules::Resolver.reset_cache

      expect(FieldRule.where(field_key: key)).to exist
      contract = nil
      expect { contract = create_contract }.not_to raise_error
      expect(contract.errors.symbols_for(:"custom_field_#{custom_field.id}")).to be_empty
    end

    it "ignores the rule in a project where the custom field is not active" do
      custom_field.update_columns(is_for_all: false)
      project.work_package_custom_fields.clear
      FieldRules::Resolver.reset_cache

      expect(create_contract.errors.symbols_for(:"custom_field_#{custom_field.id}")).to be_empty
    end

    it "lets repair remove the orphan rule and is idempotent" do
      custom_field.destroy

      expect(FieldRules::Repair.call(dry_run: false).orphan_rules).to eq 1
      expect(FieldRules::Repair.call(dry_run: false)).to have_attributes(orphan_rules: 0, invalid_rules: 0)
    end
  end

  describe "repair" do
    it "does nothing in dry run mode" do
      FieldRule.insert_all!([{ rule_set_id: rule_set.id, field_key: "assignee", hidden: true, required: true,
                               position: 7, **timestamps }])

      expect { FieldRules::Repair.call(dry_run: true) }.not_to(change { FieldRule.order(:id).pluck(:required, :read_only) })
    end

    it "leaves valid rules and work packages untouched" do
      rule_set
      work_package = create(:work_package, project:, type: bug)

      expect { FieldRules::Repair.call(dry_run: false) }
        .not_to(change { [FieldRule.order(:id).pluck(:field_key, :hidden, :required, :read_only),
                          WorkPackage.where(id: work_package.id).pick(:updated_at)] })
    end

    it "reports a required read-only rule without default, which would lock creation (known gap)" do
      pending "KNOWN GAP: Repair only looks at hidden+required and hidden+read_only (safety review #4)"
      FieldRule.insert_all!([{ rule_set_id: rule_set.id, field_key: "assignee", required: true, read_only: true,
                               position: 7, **timestamps }])

      expect(FieldRules::Repair.call(dry_run: true).invalid_rules).to eq 1
    end
  end

  describe "concurrent edits" do
    it "answers a conflict instead of raising when a rule set insert loses a unique race" do
      allow_any_instance_of(FieldRuleSet).to receive(:save).and_raise(ActiveRecord::RecordNotUnique) # rubocop:disable RSpec/AnyInstance

      result = FieldRules::RuleSetService.create(name: "Racy", rules: [{ field_key: "description", required: true }])

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:conflict)
    end

    it "answers a conflict instead of raising when a scheme insert loses a unique race" do
      allow_any_instance_of(FieldRuleScheme).to receive(:save).and_raise(ActiveRecord::RecordNotUnique) # rubocop:disable RSpec/AnyInstance

      result = FieldRules::SchemeService.create(name: "Racy", items: [{ type_id: bug.id, rule_set_id: rule_set.id }])

      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:conflict)
    end

    it "locks the rule set row while it is rewritten" do
      allow(rule_set).to receive(:lock!).and_call_original

      FieldRules::RuleSetService.update(rule_set, name: "Renamed", rules: [{ field_key: "description", required: true }])

      expect(rule_set).to have_received(:lock!)
    end

    it "locks the scheme row while it is rewritten" do
      allow(scheme).to receive(:lock!).and_call_original

      FieldRules::SchemeService.update(scheme, name: "Renamed", items: [{ type_id: bug.id, rule_set_id: rule_set.id }])

      expect(scheme).to have_received(:lock!)
    end

    it "does not leave a half-written rule set behind when validation fails" do
      before_keys = rule_set.rules.map(&:field_key)

      result = FieldRules::RuleSetService.update(rule_set, rules: [{ field_key: "description", required: true, hidden: true }])

      expect(result).to be_failure
      expect(rule_set.reload.rules.map(&:field_key)).to eq before_keys
    end

    it "lets the last writer win because the form submits the complete rule list (no optimistic lock)" do
      stale = FieldRuleSet.find(rule_set.id)
      FieldRules::RuleSetService.update(rule_set, rules: [{ field_key: "assignee", required: true }])
      FieldRules::RuleSetService.update(stale, rules: [{ field_key: "category" }])

      expect(rule_set.reload.rules.map(&:field_key)).to eq ["category"]
    end
  end
end
