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

RSpec.describe Queries::WorkPackages::VersionNames do
  describe ".canonical_select" do
    it "translates version to target_versions" do
      expect(described_class.canonical_select(:version)).to eq "target_versions"
      expect(described_class.canonical_select("version")).to eq "target_versions"
    end

    it "keeps target_versions as is" do
      expect(described_class.canonical_select(:target_versions)).to eq "target_versions"
      expect(described_class.canonical_select("target_versions")).to eq "target_versions"
    end

    it "leaves every other name untouched, preserving its type" do
      expect(described_class.canonical_select(:subject)).to eq :subject
      expect(described_class.canonical_select("assigned_to")).to eq "assigned_to"
      expect(described_class.canonical_select(nil)).to be_nil
    end
  end

  describe ".active_select" do
    context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
      it "translates version to target_versions" do
        expect(described_class.active_select(:version)).to eq "target_versions"
        expect(described_class.active_select("version")).to eq "target_versions"
      end

      it "keeps target_versions as is" do
        expect(described_class.active_select(:target_versions)).to eq "target_versions"
      end
    end

    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "translates target_versions to version" do
        expect(described_class.active_select(:target_versions)).to eq "version"
        expect(described_class.active_select("target_versions")).to eq "version"
      end

      it "keeps version as is" do
        expect(described_class.active_select(:version)).to eq "version"
      end
    end

    it "leaves every other name untouched, preserving its type" do
      expect(described_class.active_select(:subject)).to eq :subject
      expect(described_class.active_select("assigned_to")).to eq "assigned_to"
      expect(described_class.active_select(nil)).to be_nil
    end
  end

  describe ".canonical_filter" do
    it "translates version_id to target_version_id" do
      expect(described_class.canonical_filter(:version_id)).to eq "target_version_id"
      expect(described_class.canonical_filter("version_id")).to eq "target_version_id"
    end

    it "keeps target_version_id as is" do
      expect(described_class.canonical_filter(:target_version_id)).to eq "target_version_id"
    end

    it "leaves every other key untouched, preserving its type" do
      expect(described_class.canonical_filter(:status_id)).to eq :status_id
      expect(described_class.canonical_filter("assigned_to_id")).to eq "assigned_to_id"
      expect(described_class.canonical_filter(nil)).to be_nil
    end
  end

  describe ".active_filter" do
    context "with multiple versions active", with_settings: { work_package_multiple_versions: true } do
      it "translates version_id to target_version_id" do
        expect(described_class.active_filter(:version_id)).to eq "target_version_id"
        expect(described_class.active_filter("version_id")).to eq "target_version_id"
      end

      it "keeps target_version_id as is" do
        expect(described_class.active_filter(:target_version_id)).to eq "target_version_id"
      end
    end

    context "with multiple versions inactive", with_settings: { work_package_multiple_versions: false } do
      it "translates target_version_id to version_id" do
        expect(described_class.active_filter(:target_version_id)).to eq "version_id"
        expect(described_class.active_filter("target_version_id")).to eq "version_id"
      end

      it "keeps version_id as is" do
        expect(described_class.active_filter(:version_id)).to eq "version_id"
      end
    end

    it "leaves every other key untouched, preserving its type" do
      expect(described_class.active_filter(:status_id)).to eq :status_id
      expect(described_class.active_filter("assigned_to_id")).to eq "assigned_to_id"
      expect(described_class.active_filter(nil)).to be_nil
    end
  end
end
