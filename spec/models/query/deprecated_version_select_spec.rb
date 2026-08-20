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

RSpec.describe Query::DeprecatedVersionSelect do
  # A query saved with either name has to keep working - and stay valid - once
  # the multiple-versions feature is toggled.
  subject(:query) do
    build(:query,
          column_names: %i[id subject version],
          group_by: "version",
          sort_criteria: [%w[version asc]])
  end

  describe ".normalize_name" do
    context "with multiple versions active",
            with_settings: { work_package_multiple_versions: true } do
      it "translates the version name to target_versions" do
        expect(described_class.normalize_name(:version)).to eq "target_versions"
        expect(described_class.normalize_name("version")).to eq "target_versions"
      end

      it "keeps the target_versions name" do
        expect(described_class.normalize_name(:target_versions)).to eq "target_versions"
      end
    end

    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "translates the target_versions name to version" do
        expect(described_class.normalize_name(:target_versions)).to eq "version"
        expect(described_class.normalize_name("target_versions")).to eq "version"
      end

      it "keeps the version name" do
        expect(described_class.normalize_name(:version)).to eq "version"
      end
    end

    it "keeps every other name untouched" do
      expect(described_class.normalize_name(:subject)).to eq :subject
      expect(described_class.normalize_name("assigned_to")).to eq "assigned_to"
      expect(described_class.normalize_name(nil)).to be_nil
    end
  end

  context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
    it "reads the stored version name as target_versions" do
      expect(query.column_names).to eq %i[id subject target_versions]
      expect(query.group_by).to eq "target_versions"
      expect(query.sort_criteria).to eq [%w[target_versions asc]]
    end

    it "keeps the column, grouping and sorting in place" do
      expect(query.columns.map(&:name)).to eq %i[id subject target_versions]
      expect(query.group_by_column.name).to eq :target_versions
      expect(query.sort_criteria_columns.map { |column, _| column.name }).to eq %i[target_versions]
    end

    it "is valid and survives valid_subset!" do
      expect(query).to be_valid

      query.valid_subset!

      expect(query.column_names).to include :target_versions
      expect(query.group_by).to eq "target_versions"
      expect(query.sort_criteria).to eq [%w[target_versions asc]]
    end

    it "does not list the column twice when both names are stored" do
      query.column_names = %i[id version target_versions]

      expect(query.column_names).to eq %i[id target_versions]
    end

    it "translates on read only, leaving the stored attributes alone" do
      query.save!
      query.column_names && query.group_by && query.sort_criteria

      expect(query).not_to be_changed
      expect(query.reload.read_attribute(:sort_criteria)).to eq [%w[version asc]]
    end
  end

  context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
    subject(:query) do
      build(:query,
            column_names: %i[id subject target_versions],
            group_by: "target_versions",
            sort_criteria: [%w[target_versions asc]])
    end

    it "reads the stored target_versions name as version" do
      expect(query.column_names).to eq %i[id subject version]
      expect(query.group_by).to eq "version"
      expect(query.sort_criteria).to eq [%w[version asc]]
    end

    it "is valid and keeps the column, grouping and sorting in place" do
      expect(query).to be_valid
      expect(query.columns.map(&:name)).to eq %i[id subject version]
      expect(query.group_by_column.name).to eq :version
      expect(query.sort_criteria_columns.map { |column, _| column.name }).to eq %i[version]
    end
  end

  context "with default columns and multiple versions active",
          with_settings: { work_package_multiple_versions: true,
                           work_package_list_default_columns: %w[id subject version] } do
    subject(:query) { build(:query, column_names: []) }

    it "translates the default version column to target_versions" do
      expect(query.columns.map(&:name)).to eq %i[id subject target_versions]
    end
  end
end
