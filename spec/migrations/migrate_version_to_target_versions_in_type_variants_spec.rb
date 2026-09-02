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
      .to match_array(%w[target_versions priority])
  end

  it "dedupes form_configuration_excluded_elements when a row already excludes both keys" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(excluded_elements_both_variant.reload.read_attribute(:form_configuration_excluded_elements))
      .to match_array(%w[target_versions priority])
  end

  it "renames the sole version attribute help text to target_versions" do
    help_text = create(:work_package_help_text, attribute_name: "status")
    help_text.update_column(:attribute_name, "version")

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(help_text.reload.attribute_name).to eq("target_versions")
  end

  it "leaves a version row untouched when a target_versions row already exists" do
    survivor = create(:work_package_help_text, attribute_name: "target_versions")
    duplicate = create(:work_package_help_text, attribute_name: "status")
    duplicate.update_column(:attribute_name, "version")
    duplicate_attachment = create(:attachment, container: duplicate)

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(survivor.reload.attribute_name).to eq("target_versions")
    expect(duplicate.reload.attribute_name).to eq("version")
    expect(Attachment.exists?(duplicate_attachment.id)).to be true
  end

  it "renames only the lowest-id version row when several exist and no target_versions row exists" do
    lower_id_help_text = create(:work_package_help_text, attribute_name: "status")
    lower_id_help_text.update_column(:attribute_name, "version")
    lower_id_attachment = create(:attachment, container: lower_id_help_text)
    higher_id_help_text = create(:work_package_help_text, attribute_name: "priority")
    higher_id_help_text.update_column(:attribute_name, "version")
    higher_id_attachment = create(:attachment, container: higher_id_help_text)

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(lower_id_help_text.reload.attribute_name).to eq("target_versions")
    expect(higher_id_help_text.reload.attribute_name).to eq("version")
    expect(Attachment.exists?(lower_id_attachment.id)).to be true
    expect(Attachment.exists?(higher_id_attachment.id)).to be true
  end

  it "leaves a non-WorkPackage attribute help text named version untouched" do
    project_help_text = create(:project_help_text, attribute_name: "members")
    project_help_text.update_column(:attribute_name, "version")

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(project_help_text.reload.attribute_name).to eq("version")
  end

  it "leaves a work package attribute help text with another attribute name untouched" do
    status_help_text = create(:work_package_help_text, attribute_name: "status")

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(status_help_text.reload.attribute_name).to eq("status")
  end

  it "leaves migrated data unchanged when rolled back" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
    attribute_groups_after_up = duplicate_after_rename_variant.reload.read_attribute(:attribute_groups)
    excluded_elements_after_up = excluded_elements_variant.reload.read_attribute(:form_configuration_excluded_elements)

    expect { ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) } }.not_to raise_error

    expect(duplicate_after_rename_variant.reload.read_attribute(:attribute_groups)).to eq(attribute_groups_after_up)
    expect(excluded_elements_variant.reload.read_attribute(:form_configuration_excluded_elements))
      .to eq(excluded_elements_after_up)
  end
end
