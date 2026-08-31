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
require Rails.root.join("db/migrate/20260831120000_migrate_version_to_target_versions_in_type_variants")

RSpec.describe MigrateVersionToTargetVersionsInTypeVariants, type: :model do
  shared_let(:mixed_group_and_key_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:attribute_groups, [
                              ["details", %w[category version]],
                              ["version", %w[subject], "Version"],
                              ["Related", [:query_1]] # rubocop:disable Naming/VariableNumber
                            ])
    end
  end

  shared_let(:duplicate_after_rename_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:attribute_groups, [["details", %w[version target_versions]]])
    end
  end

  shared_let(:cross_group_with_original_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:attribute_groups, [["a", %w[version]], ["b", %w[target_versions]]])
    end
  end

  shared_let(:cross_group_without_original_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:attribute_groups, [["a", %w[version]], ["b", %w[version subject]]])
    end
  end

  shared_let(:untouched_variant) do
    create(:type).default_variant.tap { |variant| variant.update_column(:attribute_groups, nil) }
  end

  shared_let(:no_version_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:attribute_groups, [["a", %w[category subject]]])
    end
  end

  shared_let(:excluded_elements_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:form_configuration_excluded_elements, %w[version priority])
    end
  end

  shared_let(:excluded_elements_both_variant) do
    create(:type).default_variant.tap do |variant|
      variant.update_column(:form_configuration_excluded_elements, %w[version target_versions priority])
    end
  end

  it "renames the version attribute to target_versions, leaving group keys and query members alone" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(mixed_group_and_key_variant.reload.read_attribute(:attribute_groups)).to eq(
      [
        ["details", %w[category target_versions]],
        ["version", %w[subject], "Version"],
        ["Related", [:query_1]] # rubocop:disable Naming/VariableNumber
      ]
    )
  end

  it "dedupes an attribute list that already contains both version and target_versions" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(duplicate_after_rename_variant.reload.read_attribute(:attribute_groups)).to eq(
      [["details", %w[target_versions]]]
    )
  end

  it "leaves a NULL attribute_groups column untouched" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(untouched_variant.reload.attribute_groups_before_type_cast).to be_nil
  end

  it "drops the renamed attribute from every group but the first when another group already has target_versions" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(cross_group_with_original_variant.reload.read_attribute(:attribute_groups)).to eq(
      [["a", []], ["b", %w[target_versions]]]
    )
  end

  it "renames only the first version occurrence across groups when no group has an original target_versions" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(cross_group_without_original_variant.reload.read_attribute(:attribute_groups)).to eq(
      [["a", %w[target_versions]], ["b", %w[subject]]]
    )
  end

  it "leaves a row without a version attribute byte-identical" do
    raw_attribute_groups = no_version_variant.attribute_groups_before_type_cast

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(no_version_variant.reload.attribute_groups_before_type_cast).to eq(raw_attribute_groups)
  end

  it "renames version to target_versions in form_configuration_excluded_elements" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(excluded_elements_variant.reload.read_attribute(:form_configuration_excluded_elements))
      .to eq(%w[target_versions priority])
  end

  it "dedupes form_configuration_excluded_elements when a row already excludes both keys" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(excluded_elements_both_variant.reload.read_attribute(:form_configuration_excluded_elements))
      .to match_array(%w[target_versions priority])
  end
end
