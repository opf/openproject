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
  let(:form) { type.default_variant.form_configuration }

  before { RequestStore.clear! }

  def call = described_class.new(form).call

  def groups_as_tuples
    form.form_groups.reload.map do |group|
      [group.default_key.to_sym, group.members.map(&:key)]
    end
  end

  it "creates the default groups in default order with their members placed" do
    result = call

    expect(result).to be_success
    expect(groups_as_tuples).to eq form.default_attribute_groups
    expect(form.form_groups.pluck(:kind).uniq).to eq [FormConfigurationGroup::ATTRIBUTE]
    expect(form.form_groups.pluck(:label).uniq).to eq [nil]
    expect(form.form_groups.pluck(:position)).to eq (1..form.form_groups.size).to_a
  end

  it "leaves every other catalog attribute inactive" do
    call

    active_keys = form.form_attributes.active.map(&:key)
    inactive_keys = form.form_attributes.inactive.map(&:key)

    expect(active_keys + inactive_keys).to match_array form.work_package_attributes.keys
    expect(active_keys & inactive_keys).to be_empty
  end

  it "omits estimates and progress for a milestone type it generates the form for" do
    type.update!(is_milestone: true)

    described_class.new(form, from: type.default_variant).call

    expect(form.form_groups.pluck(:default_key)).not_to include "estimates_and_progress"
  end

  it "puts active custom fields into the other group" do
    custom_field = create(:wp_custom_field)
    form.custom_fields << custom_field
    RequestStore.clear!

    call

    other = form.form_groups.find_by(default_key: "other")
    expect(other.members.map(&:key)).to include "custom_field_#{custom_field.id}"
  end

  it "refuses an owner that already has records and writes nothing" do
    create(:form_configuration_group, form_configuration: form, label: "Custom")

    result = call

    expect(result).to be_failure
    expect(form.form_groups.count).to eq 1
    expect(form.form_attributes).to be_empty
  end

  it "writes the defaults of the variant it is given, so a milestone's form has no estimates" do
    milestone = create(:type_milestone).default_variant

    described_class.new(milestone.form_configuration, from: milestone).call

    expect(milestone.form_configuration.form_groups.pluck(:default_key)).not_to include("estimates_and_progress")
  end
end
