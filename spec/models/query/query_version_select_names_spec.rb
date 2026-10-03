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

RSpec.describe Query do
  shared_examples_for "a query storing the canonical version select" do |active_name:|
    it "stores target_versions regardless of the assigned name" do
      expect(query.read_attribute(:column_names)).to eq %i[id subject target_versions]
      expect(query.read_attribute(:sort_criteria)).to eq [%w[target_versions asc]]
      expect(query.read_attribute(:group_by)).to eq "target_versions"
    end

    it "reads back the name the setting currently offers" do
      expect(query.column_names).to eq [:id, :subject, active_name]
      expect(query.group_by).to eq active_name.to_s
      expect(query.sort_criteria).to eq [[active_name.to_s, "asc"]]
    end

    it "resolves columns, group_by_column and sort_criteria_columns" do
      expect(query.columns.map(&:name)).to eq [:id, :subject, active_name]
      expect(query.group_by_column.name).to eq active_name
      expect(query.sort_criteria_columns.map { |column, _| column.name }).to eq [active_name]
    end

    it "is valid and survives valid_subset! with the version select intact" do
      expect(query).to be_valid

      query.valid_subset!

      expect(query.column_names).to include active_name
      expect(query.group_by).to eq active_name.to_s
      expect(query.sort_criteria).to eq [[active_name.to_s, "asc"]]
    end

    it "does not change the record merely by reading the translated accessors" do
      query.save!

      query.column_names
      query.group_by
      query.sort_criteria

      expect(query).not_to be_changed
    end
  end

  context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
    subject(:query) { build(:query) }

    context "when built with the legacy version name" do
      subject(:query) do
        build(:query,
              column_names: %i[id subject version],
              group_by: "version",
              sort_criteria: [%w[version asc]])
      end

      it_behaves_like "a query storing the canonical version select", active_name: :target_versions
    end

    context "when built with the target_versions name" do
      subject(:query) do
        build(:query,
              column_names: %i[id subject target_versions],
              group_by: "target_versions",
              sort_criteria: [%w[target_versions asc]])
      end

      it_behaves_like "a query storing the canonical version select", active_name: :target_versions
    end

    it "dedupes column_names when both names are assigned" do
      query.column_names = %i[id version target_versions]

      expect(query.column_names).to eq %i[id target_versions]
    end

    it "dedupes sort_criteria when both names are assigned, keeping the first entry" do
      query.sort_criteria = [%w[version asc], %w[target_versions desc]]

      expect(query.sort_criteria).to eq [%w[target_versions asc]]
    end

    context "with default columns", with_settings: { work_package_list_default_columns: %w[id subject target_versions] } do
      subject(:query) { build(:query, column_names: []) }

      it "resolves the default version column to the active name" do
        expect(query.columns.map(&:name)).to eq %i[id subject target_versions]
      end
    end
  end

  context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
    subject(:query) { build(:query) }

    context "when built with the legacy version name" do
      subject(:query) do
        build(:query,
              column_names: %i[id subject version],
              group_by: "version",
              sort_criteria: [%w[version asc]])
      end

      it_behaves_like "a query storing the canonical version select", active_name: :version
    end

    context "when built with the target_versions name" do
      subject(:query) do
        build(:query,
              column_names: %i[id subject target_versions],
              group_by: "target_versions",
              sort_criteria: [%w[target_versions asc]])
      end

      it_behaves_like "a query storing the canonical version select", active_name: :version
    end

    it "dedupes column_names when both names are assigned" do
      query.column_names = %i[id version target_versions]

      expect(query.column_names).to eq %i[id version]
    end

    it "dedupes sort_criteria when both names are assigned, keeping the first entry" do
      query.sort_criteria = [%w[version asc], %w[target_versions desc]]

      expect(query.sort_criteria).to eq [%w[version asc]]
    end

    context "with default columns", with_settings: { work_package_list_default_columns: %w[id subject target_versions] } do
      subject(:query) { build(:query, column_names: []) }

      it "resolves the default version column to the active name" do
        expect(query.columns.map(&:name)).to eq %i[id subject version]
      end
    end
  end
end
