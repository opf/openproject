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

RSpec.describe Queries::WorkPackages::StoredNames do
  describe ".stored_select" do
    it "translates an aliased name to its stored name" do
      expect(described_class.stored_select(:version)).to eq "target_versions"
      expect(described_class.stored_select("version")).to eq "target_versions"
    end

    it "keeps a stored name untouched when it is the offered one" do
      key = :target_versions
      expect(described_class.stored_select(key)).to equal(key)
      expect(described_class.stored_select("target_versions")).to eq "target_versions"
    end

    it "leaves every other name untouched, preserving its type" do
      expect(described_class.stored_select(:subject)).to eq :subject
      expect(described_class.stored_select("assigned_to")).to eq "assigned_to"
      expect(described_class.stored_select(nil)).to be_nil
    end
  end

  describe ".offered_select" do
    context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
      it "translates an aliased name to its offered name" do
        expect(described_class.offered_select(:version)).to eq "target_versions"
        expect(described_class.offered_select("version")).to eq "target_versions"
      end

      it "keeps a stored name untouched when it is the offered one" do
        key = :target_versions
        expect(described_class.offered_select(key)).to equal(key)
      end
    end

    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "translates a stored name to its offered name" do
        expect(described_class.offered_select(:target_versions)).to eq "version"
        expect(described_class.offered_select("target_versions")).to eq "version"
      end

      it "keeps an aliased name untouched when it is the offered one" do
        key = :version
        expect(described_class.offered_select(key)).to equal(key)
      end
    end

    it "leaves every other name untouched, preserving its type" do
      expect(described_class.offered_select(:subject)).to eq :subject
      expect(described_class.offered_select("assigned_to")).to eq "assigned_to"
      expect(described_class.offered_select(nil)).to be_nil
    end
  end

  describe ".stored_filter" do
    it "translates an aliased key to its stored key" do
      expect(described_class.stored_filter(:version_id)).to eq "target_version_id"
      expect(described_class.stored_filter("version_id")).to eq "target_version_id"
    end

    it "keeps a stored key untouched when it is the offered one" do
      key = :target_version_id
      expect(described_class.stored_filter(key)).to equal(key)
    end

    it "keeps a custom field key untouched" do
      expect(described_class.stored_filter("cf_12")).to eq "cf_12"
    end

    it "leaves every other key untouched, preserving its type" do
      key = :status_id
      expect(described_class.stored_filter(key)).to equal(key)
      expect(described_class.stored_filter("assigned_to_id")).to eq "assigned_to_id"
      expect(described_class.stored_filter(nil)).to be_nil
    end
  end

  describe ".offered_filter" do
    it "leaves an unrelated key untouched without instantiating any filter" do
      expect(Queries::WorkPackages::Filter::StatusFilter).not_to receive(:create!) # rubocop:disable RSpec/MessageSpies
      expect(Queries::WorkPackages::Filter::CustomFieldFilter).not_to receive(:create!) # rubocop:disable RSpec/MessageSpies

      key = :status_id
      expect(described_class.offered_filter(key)).to equal(key)
    end

    context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
      it "translates a stored key to its aliased key" do
        expect(described_class.offered_filter(:version_id)).to eq "target_version_id"
        expect(described_class.offered_filter("version_id")).to eq "target_version_id"
      end

      it "keeps a stored key untouched when it is the offered one" do
        key = :target_version_id
        expect(described_class.offered_filter(key)).to equal(key)
      end
    end

    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "translates a stored key to its aliased key" do
        expect(described_class.offered_filter(:target_version_id)).to eq "version_id"
        expect(described_class.offered_filter("target_version_id")).to eq "version_id"
      end

      it "keeps a stored key untouched when it is the offered one" do
        key = :version_id
        expect(described_class.offered_filter(key)).to equal(key)
      end
    end

    it "leaves every other key untouched, preserving its type" do
      expect(described_class.offered_filter(:status_id)).to eq :status_id
      expect(described_class.offered_filter("assigned_to_id")).to eq "assigned_to_id"
      expect(described_class.offered_filter(nil)).to be_nil
    end
  end
end
