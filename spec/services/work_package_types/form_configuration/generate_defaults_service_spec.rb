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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GenerateDefaultsService do
  shared_let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  before { RequestStore.clear! }

  def call = described_class.new(variant).call

  def groups_as_tuples
    variant.form_groups.reload.map do |group|
      [group.default_key.to_sym, group.members.map(&:key)]
    end
  end

  it "creates the default groups in default order with their members placed" do
    result = call

    expect(result).to be_success
    expect(groups_as_tuples).to eq variant.default_attribute_groups
    expect(variant.form_groups.pluck(:kind).uniq).to eq [FormConfigurationGroup::ATTRIBUTE]
    expect(variant.form_groups.pluck(:label).uniq).to eq [nil]
    expect(variant.form_groups.pluck(:position)).to eq (1..variant.form_groups.size).to_a
  end

  it "leaves every other catalog attribute inactive" do
    call

    active_keys = variant.form_attributes.active.map(&:key)
    inactive_keys = variant.form_attributes.inactive.map(&:key)

    expect(active_keys + inactive_keys).to match_array variant.work_package_attributes.keys
    expect(active_keys & inactive_keys).to be_empty
  end

  it "omits estimates and progress for milestones" do
    type.update!(is_milestone: true)

    call

    expect(variant.form_groups.pluck(:default_key)).not_to include "estimates_and_progress"
  end

  it "puts active custom fields into the other group" do
    custom_field = create(:wp_custom_field)
    variant.custom_fields << custom_field
    RequestStore.clear!

    call

    other = variant.form_groups.find_by(default_key: "other")
    expect(other.members.map(&:key)).to include "custom_field_#{custom_field.id}"
  end

  it "refuses an owner that already has records and writes nothing" do
    create(:form_configuration_group, type_variant: variant, label: "Custom")

    result = call

    expect(result).to be_failure
    expect(variant.form_groups.count).to eq 1
    expect(variant.form_attributes).to be_empty
  end

  it "refuses a linked variant" do
    linked = create(:type_variant, type:)
    linked.link!(TypeVariant::FORM_CONFIGURATION)

    result = described_class.new(linked).call

    expect(result).to be_failure
    expect(linked.form_groups).to be_empty
  end
end
