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

RSpec.describe FieldRuleSet do
  it "requires a unique, bounded name" do
    create(:field_rule_set, name: "Bug rules")
    expect(build(:field_rule_set, name: "Bug rules")).not_to be_valid
    expect(build(:field_rule_set, name: "x" * 256)).not_to be_valid
  end

  it "rejects duplicate fields" do
    rule_set = build(:field_rule_set, rule_attributes: [{ field_key: "description" }, { field_key: "description" }])
    expect(rule_set).not_to be_valid
    expect(rule_set.errors.symbols_for(:rules)).to include(:duplicate_fields)
  end

  it "cannot be destroyed" do
    rule_set = create(:field_rule_set)
    expect(rule_set.destroy).to be(false)
    expect(described_class.exists?(rule_set.id)).to be(true)
  end
end

RSpec.describe FieldRuleScheme do
  let(:type) { create(:type) }
  let(:rule_set) { create(:field_rule_set) }

  it "cannot be destroyed" do
    scheme = create(:field_rule_scheme)
    expect(scheme.destroy).to be(false)
  end

  it "rejects the same type twice" do
    scheme = build(:field_rule_scheme)
    2.times { scheme.items.build(type:, rule_set:) }
    expect(scheme).not_to be_valid
    expect(scheme.errors.symbols_for(:items)).to include(:duplicate_types)
  end

  it "resolves the rule set for a type" do
    scheme = create(:field_rule_scheme, mapping: { type => rule_set })
    expect(scheme.rule_set_for(type.id)).to eq rule_set
  end
end

RSpec.describe ProjectFieldRuleScheme do
  it "allows one scheme per project and only active schemes" do
    project = create(:project)
    scheme = create(:field_rule_scheme)
    described_class.create!(project:, scheme:)

    expect(described_class.new(project:, scheme:)).not_to be_valid
    inactive = create(:field_rule_scheme, active: false)
    expect(described_class.new(project: create(:project), scheme: inactive)).not_to be_valid
  end
end
