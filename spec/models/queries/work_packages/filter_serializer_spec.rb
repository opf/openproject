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

RSpec.describe Queries::WorkPackages::FilterSerializer do
  describe ".dump", with_settings: { work_package_multiple_versions: false } do
    it "stores a VersionFilter object under target_version_id" do
      filter = Queries::WorkPackages::Filter::VersionFilter.create!(operator: "=", values: %w[1 2])

      yaml = described_class.dump([filter])

      expect(YAML.load(yaml, permitted_classes: [Symbol]).keys).to eq ["target_version_id"]
    end

    it "stores a raw version_id hash under target_version_id" do
      yaml = described_class.dump([{ version_id: { operator: "=", values: %w[1] } }])

      expect(YAML.load(yaml, permitted_classes: [Symbol]).keys).to eq ["target_version_id"]
    end

    it "keeps the target_version_id entry when both keys are present" do
      yaml = described_class.dump(
        [
          { version_id: { operator: "=", values: %w[1] } },
          { target_version_id: { operator: "=", values: %w[2] } }
        ]
      )

      loaded = YAML.load(yaml, permitted_classes: [Symbol]).transform_values(&:with_indifferent_access)

      expect(loaded.keys).to eq ["target_version_id"]
      expect(loaded["target_version_id"]["values"]).to eq %w[2]
    end
  end

  describe ".load" do
    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "loads a stored target_version_id as a VersionFilter with its values intact" do
        yaml = YAML.dump("target_version_id" => { "operator" => "=", "values" => %w[1 2] })

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::VersionFilter)
        expect(filters.sole.operator).to eq "="
        expect(filters.sole.values).to eq %w[1 2]
      end
    end

    context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
      it "loads a stored target_version_id as a TargetVersionsFilter" do
        yaml = YAML.dump("target_version_id" => { "operator" => "=", "values" => %w[1 2] })

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::TargetVersionsFilter)
      end

      it "loads a legacy stored version_id as a TargetVersionsFilter" do
        yaml = YAML.dump("version_id" => { "operator" => "=", "values" => %w[1 2] })

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::TargetVersionsFilter)
      end

      it "keeps the target_version_id entry's values when both keys are stored" do
        yaml = YAML.dump(
          "version_id" => { "operator" => "=", "values" => %w[1] },
          "target_version_id" => { "operator" => "=", "values" => %w[2] }
        )

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::TargetVersionsFilter)
        expect(filters.sole.values).to eq %w[2]
      end

      it "keeps the target_version_id entry's values regardless of key order" do
        yaml = YAML.dump(
          "target_version_id" => { "operator" => "=", "values" => %w[2] },
          "version_id" => { "operator" => "=", "values" => %w[1] }
        )

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::TargetVersionsFilter)
        expect(filters.sole.values).to eq %w[2]
      end
    end

    context "with multiple versions inactive and both keys stored",
            with_settings: { work_package_multiple_versions: false } do
      it "keeps the target_version_id entry's values as a VersionFilter" do
        yaml = YAML.dump(
          "version_id" => { "operator" => "=", "values" => %w[1] },
          "target_version_id" => { "operator" => "=", "values" => %w[2] }
        )

        filters = described_class.load(yaml)

        expect(filters.sole).to be_a(Queries::WorkPackages::Filter::VersionFilter)
        expect(filters.sole.values).to eq %w[2]
      end
    end
  end

  describe "round trip" do
    it "keeps the operator and values through dump then load", with_settings: { work_package_multiple_versions: true } do
      filter = Queries::WorkPackages::Filter::TargetVersionsFilter.create!(operator: "=", values: %w[3 4])

      filters = described_class.load(described_class.dump([filter]))

      expect(filters.sole.operator).to eq "="
      expect(filters.sole.values).to eq %w[3 4]
    end
  end
end
