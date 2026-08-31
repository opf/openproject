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

RSpec.describe Query::DeprecatedVersionFilter do
  # A query saved with either filter key has to keep working - and stay
  # valid - once the multiple-versions feature is toggled.
  shared_let(:project) { create(:project) }
  shared_let(:version) { create(:version, project:) }
  shared_let(:admin) { create(:admin) }

  before { login_as(admin) }

  subject(:query) { build(:query, project:) }

  def store_raw_filters(query, filters_hash)
    Query.where(id: query.id).update_all(["filters = ?", YAML.dump(filters_hash)])
  end

  describe ".normalize_key" do
    context "with multiple versions active",
            with_settings: { work_package_multiple_versions: true } do
      it "translates the version_id key to target_version_id" do
        expect(described_class.normalize_key(:version_id)).to eq "target_version_id"
        expect(described_class.normalize_key("version_id")).to eq "target_version_id"
      end

      it "keeps the target_version_id key" do
        expect(described_class.normalize_key(:target_version_id)).to eq "target_version_id"
      end
    end

    context "with multiple versions inactive",
            with_settings: { work_package_multiple_versions: false } do
      it "translates the target_version_id key to version_id" do
        expect(described_class.normalize_key(:target_version_id)).to eq "version_id"
        expect(described_class.normalize_key("target_version_id")).to eq "version_id"
      end

      it "keeps the version_id key" do
        expect(described_class.normalize_key(:version_id)).to eq "version_id"
      end
    end

    it "keeps every other key untouched" do
      expect(described_class.normalize_key(:subject)).to eq :subject
      expect(described_class.normalize_key("assigned_to_id")).to eq "assigned_to_id"
      expect(described_class.normalize_key(nil)).to be_nil
    end
  end

  context "with multiple versions active",
          with_settings: { work_package_multiple_versions: true } do
    it "instantiates the target_versions filter for the version_id key" do
      query.add_filter("version_id", "=", [version.id.to_s])

      filter = query.filters.last
      expect(filter).to be_a(Queries::WorkPackages::Filter::TargetVersionsFilter)
      expect(filter.name).to eq :target_version_id
      expect(filter.operator).to eq "="
      expect(filter.values).to eq [version.id.to_s]
    end

    it "loads a stored version_id filter as the target_versions filter" do
      filters = Queries::WorkPackages::FilterSerializer
                  .load(YAML.dump({ "version_id" => { "operator" => "=", "values" => [version.id.to_s] } }))

      expect(filters.map(&:name)).to eq [:target_version_id]
      expect(filters.first.values).to eq [version.id.to_s]
    end

    it "keeps a persisted version_id filter across reload and valid_subset!" do
      query.save!
      store_raw_filters(query, { "version_id" => { "operator" => "=", "values" => [version.id.to_s] } })

      reloaded = Query.find(query.id)
      expect(reloaded.filters.map(&:name)).to contain_exactly(:target_version_id)

      reloaded.valid_subset!

      expect(reloaded.filters.map(&:name)).to contain_exactly(:target_version_id)
      expect(reloaded.filters.first.values).to eq [version.id.to_s]
    end

    it "keeps only the active key's entry when both keys are stored" do
      other_version = create(:version, project:)
      query.save!
      store_raw_filters(query,
                        { "version_id" => { "operator" => "=", "values" => [other_version.id.to_s] },
                          "target_version_id" => { "operator" => "=", "values" => [version.id.to_s] } })

      reloaded = Query.find(query.id)

      expect(reloaded.filters.map(&:name)).to contain_exactly(:target_version_id)
      expect(reloaded.filters.first.values).to eq [version.id.to_s]
    end

    it "offers only the target_versions filter" do
      names = query.available_filters.map(&:name)

      expect(names).to include(:target_version_id)
      expect(names).not_to include(:version_id)
    end
  end

  context "with multiple versions inactive",
          with_settings: { work_package_multiple_versions: false } do
    it "instantiates the version filter for the target_version_id key" do
      query.add_filter("target_version_id", "=", [version.id.to_s])

      filter = query.filters.last
      expect(filter).to be_a(Queries::WorkPackages::Filter::VersionFilter)
      expect(filter.name).to eq :version_id
      expect(filter.operator).to eq "="
      expect(filter.values).to eq [version.id.to_s]
    end

    it "keeps a persisted target_version_id filter across reload and valid_subset!" do
      query.save!
      store_raw_filters(query, { "target_version_id" => { "operator" => "=", "values" => [version.id.to_s] } })

      reloaded = Query.find(query.id)
      expect(reloaded.filters.map(&:name)).to contain_exactly(:version_id)

      reloaded.valid_subset!

      expect(reloaded.filters.map(&:name)).to contain_exactly(:version_id)
      expect(reloaded.filters.first.values).to eq [version.id.to_s]
    end

    it "offers only the version filter" do
      names = query.available_filters.map(&:name)

      expect(names).to include(:version_id)
      expect(names).not_to include(:target_version_id)
    end
  end
end
