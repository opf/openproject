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

RSpec.describe FieldRule do
  let(:rule_set) { create(:field_rule_set) }

  def build_rule(**attrs) = described_class.new({ rule_set:, field_key: "description" }.merge(attrs))

  it "accepts a configurable native field" do
    expect(build_rule(required: true)).to be_valid
  end

  it "rejects fields outside the allowlist" do
    expect(build_rule(field_key: "subject")).not_to be_valid
    expect(build_rule(field_key: "type")).not_to be_valid
    expect(build_rule(field_key: "custom_field_0")).not_to be_valid
  end

  it "accepts an existing work package custom field" do
    custom_field = create(:work_package_custom_field)
    expect(build_rule(field_key: "custom_field_#{custom_field.id}")).to be_valid
  end

  it "rejects hidden together with required" do
    rule = build_rule(hidden: true, required: true)
    expect(rule).not_to be_valid
    expect(rule.errors.symbols_for(:required)).to include(:hidden_and_required)
  end

  it "needs a default for required and read-only" do
    rule = build_rule(required: true, read_only: true)
    expect(rule).not_to be_valid
    expect(rule.errors.symbols_for(:required)).to include(:read_only_required_without_default)
    expect(build_rule(required: true, read_only: true, default_value: "text")).to be_valid
  end

  it "normalizes read-only to false when hidden" do
    rule = build_rule(hidden: true, read_only: true)
    rule.valid?
    expect(rule.read_only).to be(false)
  end

  it "validates defaults per field kind" do
    expect(build_rule(field_key: "start_date", default_value: "2026-01-31")).to be_valid
    expect(build_rule(field_key: "start_date", default_value: "31/01/2026")).not_to be_valid
    expect(build_rule(field_key: "estimated_time", default_value: "-1")).not_to be_valid
    expect(build_rule(field_key: "priority", default_value: "0")).not_to be_valid
    expect(build_rule(field_key: "target_versions", default_value: "1")).not_to be_valid
  end

  it "accepts an existing priority as default" do
    priority = create(:issue_priority)
    expect(build_rule(field_key: "priority", default_value: priority.id.to_s)).to be_valid
  end
end
