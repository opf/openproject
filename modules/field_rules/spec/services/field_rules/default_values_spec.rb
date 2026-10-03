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

RSpec.describe WorkPackages::SetAttributesService, "field rule defaults" do
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:status) { create(:default_status) }
  shared_let(:native_priority) { create(:default_priority) }
  shared_let(:high) { create(:issue_priority, name: "High") }
  shared_let(:project) { create(:project, types: [bug]) }
  shared_let(:user) { create(:admin) }

  let(:rules) do
    [{ field_key: "priority", default_value: high.id.to_s },
     { field_key: "description", default_value: "Steps to reproduce:" },
     { field_key: "start_date", default_value: "2026-03-02" }]
  end

  before do
    rule_set = create(:field_rule_set, rule_attributes: rules)
    ProjectFieldRuleScheme.create!(project:, scheme: create(:field_rule_scheme, mapping: { bug => rule_set }))
  end

  def build_with(attributes = {})
    work_package = WorkPackage.new
    described_class.new(user:, model: work_package, contract_class: WorkPackages::CreateContract)
                   .call({ project:, type: bug, subject: "x" }.merge(attributes))
    work_package
  end

  it "applies rule defaults over native defaults on create" do
    work_package = build_with

    expect(work_package.priority).to eq high
    expect(work_package.description).to eq "Steps to reproduce:"
    expect(work_package.start_date).to eq Date.new(2026, 3, 2)
  end

  it "keeps values the user provided" do
    work_package = build_with(priority: native_priority, description: "Mine")

    expect(work_package.priority).to eq native_priority
    expect(work_package.description).to eq "Mine"
  end

  it "does not touch existing work packages" do
    work_package = create(:work_package, project:, type: bug, priority: native_priority, description: "Old")

    described_class.new(user:, model: work_package, contract_class: WorkPackages::UpdateContract).call(subject: "New")

    expect(work_package.priority).to eq native_priority
    expect(work_package.description).to eq "Old"
  end

  it "does nothing for types without rules" do
    other = create(:type)
    project.types << other
    work_package = build_with(type: other)

    expect(work_package.priority).to eq native_priority
  end

  it "keeps the native result when a default cannot be applied" do
    allow(FieldRules::Fields).to receive(:apply_default).and_raise(StandardError, "boom")

    expect { build_with }.not_to raise_error
  end
end
