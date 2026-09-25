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

RSpec.describe WorkPackageTypes::FormConfiguration::ReconcileAttributesService do
  shared_let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  before { RequestStore.clear! }

  def call = described_class.new(variant).call

  it "creates one inactive membership per catalog attribute on an empty owner" do
    result = call

    expect(result).to be_success
    expect(result.result).to eq variant
    expect(variant.form_attributes.inactive.pluck(:attribute_key)).to match_array variant.work_package_attributes.keys
    expect(variant.form_attributes.active).to be_empty
  end

  it "stores custom fields by foreign key" do
    custom_field = create(:wp_custom_field)

    call

    expect(variant.form_attributes.where(custom_field:)).to exist
    expect(variant.form_attributes.where(attribute_key: "custom_field_#{custom_field.id}")).not_to exist
  end

  it "is idempotent and keeps existing ids and placement" do
    group = create(:form_configuration_group, type_variant: variant, label: "Details")
    active = create(:form_configuration_attribute, type_variant: variant, group:, position: 1, attribute_key: "subject")
    call
    ids_before = variant.form_attributes.order(:id).pluck(:id)

    call

    expect(variant.form_attributes.order(:id).pluck(:id)).to eq ids_before
    expect(active.reload.position).to eq 1
    expect(active.group).to eq group
  end

  it "adds only the attributes that are missing" do
    create(:form_configuration_attribute, type_variant: variant, attribute_key: "date")

    expect { call }.to change { variant.form_attributes.count }.by(variant.work_package_attributes.keys.size - 1)
  end

  it "does not reactivate or remove a membership the catalog no longer knows" do
    dormant = create(:form_configuration_attribute, type_variant: variant,
                                                    attribute_key: "story_points_from_removed_plugin")

    call

    expect(dormant.reload).not_to be_active
    expect(variant.form_attributes.where(id: dormant.id)).to exist
  end

  it "picks up a custom field created after the last run" do
    call
    custom_field = create(:wp_custom_field)
    RequestStore.clear!

    expect { call }.to change { variant.form_attributes.where(custom_field:).count }.from(0).to(1)
  end

  it "skips a custom field the catalog still lists but that no longer exists" do
    custom_field = create(:wp_custom_field)
    catalog = variant.work_package_attributes
    allow(variant).to receive(:work_package_attributes).and_return(catalog)
    custom_field.delete

    expect { call }.not_to raise_error
    expect(variant.form_attributes.where(custom_field_id: custom_field.id)).not_to exist
  end

  # The field vanishes after the existence check, before the insert: the check's relation is
  # forced to load before the delete runs, so the check still sees the field as present and the
  # insert is the one that hits the now-missing row and fails its foreign key.
  it "retries once without a custom field deleted between the existence check and the insert" do
    custom_field = create(:wp_custom_field)
    RequestStore.clear!
    deleted = false
    allow(WorkPackageCustomField).to receive(:where).and_wrap_original do |original, *args, **kwargs|
      relation = original.call(*args, **kwargs).load
      unless deleted
        deleted = true
        ActiveRecord::Base.connection.execute("DELETE FROM custom_fields WHERE id = #{custom_field.id}")
      end
      relation
    end
    allow(FormConfigurationAttribute).to receive(:insert_all).and_call_original

    expect { call }.not_to raise_error
    expect(FormConfigurationAttribute).to have_received(:insert_all).at_least(3).times
    expect(variant.form_attributes.where(custom_field_id: custom_field.id)).not_to exist
    expect(variant.form_attributes.where(attribute_key: "priority")).to exist
  end

  it "raises when the foreign key still fails after the retry" do
    allow(FormConfigurationAttribute).to receive(:insert_all).and_raise(ActiveRecord::InvalidForeignKey)

    expect { call }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect(FormConfigurationAttribute).to have_received(:insert_all).twice
  end

  it "reconciles the owner when given a linked variant and writes nothing for the linked one" do
    linked = create(:type_variant, type:)
    linked.link!(TypeVariant::FORM_CONFIGURATION)

    result = described_class.new(linked).call

    expect(result.result).to eq variant
    expect(linked.form_attributes).to be_empty
    expect(variant.form_attributes).not_to be_empty
  end

  it "tolerates rows another writer inserted first, for both reference kinds" do
    custom_field = create(:wp_custom_field)
    RequestStore.clear!
    injected = false
    allow(FormConfigurationAttribute).to receive(:reference_for).and_wrap_original do |original, key|
      unless injected
        injected = true
        FormConfigurationAttribute.insert_all!(
          [
            { type_variant_id: variant.id, attribute_key: "date", custom_field_id: nil },
            { type_variant_id: variant.id, attribute_key: nil, custom_field_id: custom_field.id }
          ]
        )
      end
      original.call(key)
    end
    allow(FormConfigurationAttribute).to receive(:insert_all).and_call_original

    expect { call }.not_to raise_error
    expect(FormConfigurationAttribute).to have_received(:insert_all)
      .with(array_including(hash_including(attribute_key: "date")), unique_by: described_class::KEY_INDEX)
    expect(FormConfigurationAttribute).to have_received(:insert_all)
      .with(array_including(hash_including(custom_field_id: custom_field.id)),
            unique_by: described_class::CUSTOM_FIELD_INDEX)
    expect(variant.form_attributes.where(attribute_key: "date").count).to eq 1
    expect(variant.form_attributes.where(custom_field:).count).to eq 1
  end

  it "inserts inactive rows although the table carries a deferred position constraint" do
    group = create(:form_configuration_group, type_variant: variant, label: "Details")
    create(:form_configuration_attribute, type_variant: variant, group:, position: 1, attribute_key: "priority")

    expect { call }.not_to raise_error
    expect(variant.form_attributes.inactive.count).to eq variant.work_package_attributes.keys.size - 1
  end
end
