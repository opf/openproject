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

RSpec.describe FieldRules::Resolver do
  let(:bug) { create(:type, name: "Bug") }
  let(:story) { create(:type, name: "Story") }
  let(:project) { create(:project, types: [bug, story]) }
  let(:rule_set) do
    create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true },
                                              { field_key: "priority", hidden: true },
                                              { field_key: "assignee", read_only: true }])
  end
  let(:scheme) { create(:field_rule_scheme, mapping: { bug => rule_set }) }

  it "is empty without a scheme" do
    expect(described_class.for(project, bug)).to be_empty
  end

  context "with an assigned scheme" do
    before { ProjectFieldRuleScheme.create!(project:, scheme:) }

    it "returns the rules of the type" do
      configuration = described_class.for(project, bug)

      expect(configuration.required?("description")).to be(true)
      expect(configuration.hidden?("priority")).to be(true)
      expect(configuration.read_only?("assignee")).to be(true)
      expect(configuration.editable?("assignee")).to be(false)
    end

    it "is empty for a type without an item" do
      expect(described_class.for(project, story)).to be_empty
    end

    it "ignores inactive schemes and rule sets" do
      scheme.update!(active: false)
      described_class.reset_cache
      expect(described_class.for(project, bug)).to be_empty

      scheme.update!(active: true)
      rule_set.update!(active: false)
      described_class.reset_cache
      expect(described_class.for(project, bug)).to be_empty
    end

    it "preloads many pairs with one query" do
      described_class.reset_cache
      other = create(:project, types: [bug])
      ProjectFieldRuleScheme.create!(project: other, scheme:)
      described_class.reset_cache

      result = nil
      expect { result = described_class.for_many([project.id, other.id], [bug.id, story.id]) }
        .to have_a_query_limit(1)
      expect(result[[other.id, bug.id]].required?("description")).to be(true)
      expect(result[[project.id, story.id]]).to be_empty
    end

    it "caches per request and resets after changes" do
      expect(described_class.for(project, bug).required?("description")).to be(true)
      rule_set.rules.first.update!(required: false)
      expect(described_class.for(project, bug).required?("description")).to be(false)
    end
  end

  it "does not mark a hidden rule as required" do
    rule = FieldRule.new(field_key: "description", hidden: true, required: true)
    expect(FieldRules::EffectiveField.from_rule(rule).required).to be(false)
  end

  it "falls back to native behaviour when loading fails" do
    allow(FieldRule).to receive(:joins).and_raise(StandardError, "boom")
    expect(described_class.for(project, bug)).to be_empty
  end

  it "lists conflicts with workflow requirements" do
    ProjectFieldRuleScheme.create!(project:, scheme:)
    conflicts = described_class.for(project, bug).conflicts_with("priority" => :required)
    expect(conflicts).to contain_exactly(include(field: "priority", state: :hidden))
  end
end
