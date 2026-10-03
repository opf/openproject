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
require_relative "shared_query_select_specs"

RSpec.describe Queries::WorkPackages::Selects::PropertySelect do
  let(:instance) { described_class.new(:query_column) }

  it_behaves_like "query column"

  describe "instances" do
    it "the done_ratio column exists" do
      expect(described_class.instances.map(&:name)).to include :done_ratio
    end

    context "when duration feature flag enabled" do
      it "column exists" do
        expect(described_class.instances.map(&:name)).to include :duration
      end
    end

    describe "version and target_versions columns" do
      context "with the setting enabled",
              with_settings: { work_package_multiple_versions: true } do
        it "replaces the version column with the target_versions column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :target_versions
          expect(names).not_to include :version
        end

        it "is displayable, sortable and groupable" do
          column = described_class.instances.find { it.name == :target_versions }

          expect(column).to be_displayable
          expect(column).to be_sortable
          expect(column).to be_groupable
          expect(column.caption).to eq WorkPackage.human_attribute_name(:target_versions)
        end

        it "sorts and groups via the work_package_versions join rows" do
          column = described_class.instances.find { it.name == :target_versions }

          expect(Array(column.sortable)).to all include("work_package_versions")
          expect(column.groupable).to include("work_package_versions")
        end
      end

      context "with the setting disabled",
              with_settings: { work_package_multiple_versions: false } do
        it "keeps the version column" do
          names = described_class.instances.map(&:name)

          expect(names).to include :version
          expect(names).not_to include :target_versions
        end

        it "sorts and groups the version column via the work_package_versions join rows" do
          column = described_class.instances.find { it.name == :version }

          expect(column.sortable).to include("work_package_versions")
          expect(column.groupable).to include("work_package_versions")
          expect(column.groupable).not_to include("#{WorkPackage.table_name}.version_id")
        end
      end
    end

    describe "observed_in_versions column" do
      it "is displayable, sortable and groupable" do
        column = described_class.instances.find { it.name == :observed_in_versions }

        expect(column).to be_displayable
        expect(column).to be_sortable
        expect(column).to be_groupable
        expect(column.caption).to eq WorkPackage.human_attribute_name(:observed_in_versions)
      end

      it "sorts and groups via the work_package_versions join rows, scoped to the observed_in kind" do
        column = described_class.instances.find { it.name == :observed_in_versions }

        expect(Array(column.sortable)).to all include("work_package_versions")
        expect(Array(column.sortable)).to all include("kind = 'observed_in'")
        expect(column.groupable).to include("work_package_versions")
        expect(column.groupable).to include("kind = 'observed_in'")
      end
    end
  end

  describe ".stored_name" do
    it "translates the version select to its stored target_versions column" do
      expect(described_class.stored_name(:version)).to eq "target_versions"
      expect(described_class.stored_name("version")).to eq "target_versions"
    end

    it "returns names without a stored alias untouched" do
      expect(described_class.stored_name(:target_versions)).to equal :target_versions
      expect(described_class.stored_name(:subject)).to equal :subject
      expect(described_class.stored_name("assigned_to")).to eq "assigned_to"
      expect(described_class.stored_name(:done_ratio)).to equal :done_ratio
    end

    it "returns nil and unknown names untouched" do
      expect(described_class.stored_name(nil)).to be_nil
      expect(described_class.stored_name(:nope)).to equal :nope
    end
  end

  describe ".offered_name" do
    context "with the setting enabled",
            with_settings: { work_package_multiple_versions: true } do
      it "keeps the stored target_versions column as is" do
        expect(described_class.offered_name(:target_versions)).to equal :target_versions
      end

      it "translates the retired version name to the stored target_versions column" do
        expect(described_class.offered_name("version")).to eq "target_versions"
        expect(described_class.offered_name(:version)).to eq "target_versions"
      end
    end

    context "with the setting disabled",
            with_settings: { work_package_multiple_versions: false } do
      it "translates the stored target_versions column back to version" do
        expect(described_class.offered_name(:target_versions)).to eq "version"
        expect(described_class.offered_name("target_versions")).to eq "version"
      end

      it "keeps the retired version name untouched, since it is already the offered one" do
        expect(described_class.offered_name(:version)).to equal :version
      end
    end

    it "returns names without a stored alias untouched" do
      expect(described_class.offered_name(:subject)).to equal :subject
      expect(described_class.offered_name(:done_ratio)).to equal :done_ratio
    end

    it "returns nil and unknown names untouched" do
      expect(described_class.offered_name(nil)).to be_nil
      expect(described_class.offered_name(:nope)).to equal :nope
    end

    it "returns the stored name untouched when no alias is currently offered" do
      allow(described_class).to receive(:property_selects).and_return(
        {
          foo: { if: -> { false }, stored_as: :bar },
          baz: { if: -> { false }, stored_as: :bar }
        }
      )

      expect(described_class.offered_name(:bar)).to equal :bar
    end
  end
end
