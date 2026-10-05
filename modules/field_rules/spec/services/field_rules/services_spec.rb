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

RSpec.describe FieldRules::RuleSetService do
  let(:rules) { [{ field_key: "description", required: true }, { field_key: "priority", hidden: true }] }

  it "creates a rule set with rules" do
    result = described_class.create(name: "Bug", rules:)

    expect(result).to be_success
    expect(result.result.rules.map(&:field_key)).to match_array(%w[description priority])
  end

  it "replaces rules on update without touching others" do
    rule_set = described_class.create(name: "Bug", rules:).result

    described_class.update(rule_set, rules: [{ field_key: "description", required: false, default_value: "Template" }])

    expect(rule_set.reload.rules.map(&:field_key)).to eq ["description"]
    expect(rule_set.rule_for("description").default_value).to eq "Template"
  end

  it "rejects duplicate fields and invalid combinations" do
    expect(described_class.create(name: "A", rules: [{ field_key: "description" }, { field_key: "description" }])).to be_failure
    expect(described_class.create(name: "B", rules: [{ field_key: "description", hidden: true, required: true }])).to be_failure
  end

  it "clones with a unique suffix" do
    rule_set = described_class.create(name: "Bug", rules:).result
    first = described_class.clone(rule_set).result
    second = described_class.clone(rule_set).result

    expect([first.name, second.name]).to eq ["Bug - Custom", "Bug - Custom 2"]
    expect(first.rules.size).to eq 2
  end

  it "activates and deactivates" do
    rule_set = described_class.create(name: "Bug", rules:).result
    described_class.deactivate(rule_set)
    expect(rule_set.reload).not_to be_active
    described_class.activate(rule_set)
    expect(rule_set.reload).to be_active
  end

  it "has no destroy" do
    expect(described_class).not_to respond_to(:destroy)
  end

  it "counts the impact on schemes, projects and work packages" do
    type = create(:type)
    project = create(:project, types: [type])
    rule_set = described_class.create(name: "Bug", rules:).result
    scheme = create(:field_rule_scheme, mapping: { type => rule_set })
    ProjectFieldRuleScheme.create!(project:, scheme:)
    create_list(:work_package, 2, project:, type:)

    expect(described_class.impact(rule_set)).to eq(scheme_count: 1, project_count: 1, work_package_count: 2)
  end
end

RSpec.describe FieldRules::SchemeService do
  let(:type) { create(:type) }
  let(:other_type) { create(:type) }
  let(:rule_set) { create(:field_rule_set) }

  it "creates a scheme mapping types to rule sets" do
    result = described_class.create(name: "Dev", items: [{ type_id: type.id, rule_set_id: rule_set.id }])

    expect(result).to be_success
    expect(result.result.rule_set_for(type.id)).to eq rule_set
  end

  it "replaces items on update" do
    scheme = described_class.create(name: "Dev", items: [{ type_id: type.id, rule_set_id: rule_set.id }]).result

    described_class.update(scheme, items: [{ type_id: other_type.id, rule_set_id: rule_set.id }])

    expect(scheme.reload.items.map(&:type_id)).to eq [other_type.id]
  end

  it "rejects a type twice and unknown rule sets" do
    twice = [{ type_id: type.id, rule_set_id: rule_set.id }, { type_id: type.id, rule_set_id: rule_set.id }]
    expect(described_class.create(name: "A", items: twice)).to be_failure
    expect(described_class.create(name: "B", items: [{ type_id: type.id, rule_set_id: 0 }])).to be_failure
  end

  it "assigns, reassigns and unassigns a project" do
    project = create(:project)
    first = create(:field_rule_scheme)
    second = create(:field_rule_scheme)

    expect(described_class.assign(project, first)).to be_success
    expect(described_class.assign(project, second)).to be_success
    expect(ProjectFieldRuleScheme.where(project_id: project.id).pluck(:scheme_id)).to eq [second.id]
    described_class.unassign(project)
    expect(ProjectFieldRuleScheme.where(project_id: project.id)).to be_empty
  end

  it "does not assign an inactive scheme" do
    inactive = create(:field_rule_scheme, active: false)
    expect(described_class.assign(create(:project), inactive)).to be_failure
  end
end
