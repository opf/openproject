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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::Exports::FormConfiguration do
  let(:cf_long_text) { create(:issue_custom_field, :text, name: "Notes", is_for_all: true) }
  let(:cf_bool) { create(:issue_custom_field, :boolean, name: "Flag", is_for_all: true) }
  let(:type) { create(:type_bug, custom_fields: [cf_long_text, cf_bool]) }
  let(:project) { create(:project, types: [type]) }
  let(:query) do
    query = create(:query, project:)
    query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
    query.save!
    query
  end
  let(:work_package) do
    create(:work_package, project:, type:, custom_values: { cf_long_text.id => "**bold**" })
  end
  let!(:child) { create(:work_package, project:, type:, parent: work_package) }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  subject(:groups) { described_class.new(work_package).groups }

  before do
    variant = type.default_variant
    variant.attribute_groups = [
      ["Main", [:assignee, :"custom_field_#{cf_long_text.id}", :priority, :"custom_field_#{cf_bool.id}"]],
      ["Phases", [:project_phase]],
      ["Embedded table for parent", [:"query_#{query.id}"]]
    ]
    variant.save!
    login_as(user)
  end

  it "splits a group into attribute and long-text parts in form order" do
    main = groups.first
    expect(main).to have_attributes(key: "Main", title: "Main")
    expect(main.parts.map(&:class)).to eq([described_class::AttributesPart, described_class::LongTextPart,
                                           described_class::AttributesPart])
    expect(main.parts[0].entries).to eq([described_class::Entry.new(label: WorkPackage.human_attribute_name(:assigned_to),
                                                                    name: :assigned_to)])
    expect(main.parts[1]).to eq(described_class::LongTextPart.new(label: "Notes", markdown: "**bold**"))
    expect(main.parts[2].entries.map(&:name)).to eq([:priority, :"cf_#{cf_bool.id}"])
  end

  it "drops groups whose attributes are all hidden" do
    expect(groups.map(&:key)).not_to include("Phases")
  end

  it "rebinds the templated filter and lists the related work packages" do
    query_group = groups.last
    expect(query_group).to be_a(described_class::QueryGroup)
    expect(query_group.title).to eq("Embedded table for parent")
    expect(query_group.work_packages).to eq([child])
  end

  it "skips attributes the user may not view" do
    checks = WorkPackage::Exports::Attributes.attribute_visibility_checks
    allow(checks).to receive(:[]).and_call_original
    allow(checks).to receive(:[]).with(:priority).and_return(->(_wp) { false })
    expect(groups.first.parts[2].entries.map(&:name)).to eq([:"cf_#{cf_bool.id}"])
  end

  it "keeps a group configured without attributes" do
    variant = type.default_variant
    variant.attribute_groups = [["Empty", []]]
    variant.save!

    expect(groups.map(&:key)).to eq(["Empty"])
    expect(groups.first.parts).to be_empty
  end

  context "with project-level constraints" do
    let(:project) { create(:project, types: [type], enabled_module_names: %w[work_package_tracking]) }

    before do
      variant = type.default_variant
      variant.attribute_groups = [["Planning", %i[story_points assignee]]]
      variant.save!
    end

    it "hides attributes whose module is disabled in the project" do
      expect(groups.first.parts.first.entries.map(&:name)).to eq([:assigned_to])
    end

    it "drops a group whose attributes are all constrained away" do
      variant = type.default_variant
      variant.attribute_groups = [["Backlogs only", [:story_points]]]
      variant.save!

      expect(groups).to be_empty
    end
  end
end
