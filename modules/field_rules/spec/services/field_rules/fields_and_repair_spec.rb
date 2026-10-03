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

RSpec.describe FieldRules::Fields do
  after { described_class.reset_registry! }

  it "knows native and custom fields" do
    custom_field = create(:work_package_custom_field)

    expect(described_class.configurable?("priority")).to be true
    expect(described_class.configurable?("custom_field_#{custom_field.id}")).to be true
    expect(described_class.configurable?("subject")).to be false
    expect(described_class.configurable?("status")).to be false
  end

  it "matches contract attributes per field" do
    expect(described_class.attribute_matches?("assignee", "assigned_to_id")).to be true
    expect(described_class.attribute_matches?("custom_field_12", "custom_field_12")).to be true
    expect(described_class.attribute_matches?("custom_field_1", "custom_field_12")).to be false
  end

  it "lets other modules register fields" do
    described_class.register("story_points", attributes: %w[story_points], schema_key: "storyPoints")
    expect(described_class.configurable?("story_points")).to be true
  end
end

RSpec.describe FieldRules::Repair do
  let!(:rule_set) { create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true }]) }

  it "reports and removes rules of deleted custom fields and fixes impossible states" do
    FieldRule.insert_all!([{ rule_set_id: rule_set.id, field_key: "custom_field_999999", required: false, hidden: true,
                             read_only: false, enforce_on_update: false, position: 5,
                             created_at: Time.current, updated_at: Time.current },
                           { rule_set_id: rule_set.id, field_key: "priority", required: true, hidden: true,
                             read_only: false, enforce_on_update: false, position: 6,
                             created_at: Time.current, updated_at: Time.current }])

    dry = described_class.call(dry_run: true)
    expect(dry).to have_attributes(orphan_rules: 1, invalid_rules: 1)
    expect(FieldRule.count).to eq 3

    described_class.call(dry_run: false)
    expect(FieldRule.pluck(:field_key)).to match_array(%w[description priority])
    expect(FieldRule.find_by(field_key: "priority")).not_to be_required
  end
end
