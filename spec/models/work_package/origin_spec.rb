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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::Origin do
  let(:work_package) { create(:work_package) }

  describe "validations" do
    it "allows nil origin_source" do
      work_package.origin_source = nil
      expect(work_package).to be_valid
    end

    it "allows valid origin_source values" do
      WorkPackage::Origin::SOURCES.each do |source|
        work_package.origin_source = source
        work_package.origin_id = "123"
        work_package.origin_url = "https://jira.example.com/browse/PROJ-123"
        work_package.origin_host = "https://jira.example.com"
        expect(work_package).to be_valid
      end
    end

    it "rejects invalid origin_source values" do
      work_package.origin_source = "invalid_source"
      expect(work_package).not_to be_valid
      expect(work_package.errors[:origin_source]).to be_present
    end

    it "requires origin_id when origin_source is present" do
      work_package.origin_source = "jira_data_center"
      work_package.origin_id = nil
      work_package.origin_url = "https://jira.example.com/browse/PROJ-123"
      work_package.origin_host = "https://jira.example.com"
      expect(work_package).not_to be_valid
      expect(work_package.errors[:origin_id]).to be_present
    end

    it "requires origin_url when origin_source is present" do
      work_package.origin_source = "jira_data_center"
      work_package.origin_id = "123"
      work_package.origin_url = nil
      work_package.origin_host = "https://jira.example.com"
      expect(work_package).not_to be_valid
      expect(work_package.errors[:origin_url]).to be_present
    end

    it "requires origin_host when origin_source is present" do
      work_package.origin_source = "jira_data_center"
      work_package.origin_id = "123"
      work_package.origin_url = "https://jira.example.com/browse/PROJ-123"
      work_package.origin_host = nil
      expect(work_package).not_to be_valid
      expect(work_package.errors[:origin_host]).to be_present
    end

    it "does not require origin_id when origin_source is nil" do
      work_package.origin_source = nil
      work_package.origin_id = nil
      expect(work_package).to be_valid
    end
  end

  describe "#imported?" do
    it "returns true when origin_source is present" do
      work_package.origin_source = "jira_data_center"
      expect(work_package.imported?).to be true
    end

    it "returns false when origin_source is nil" do
      work_package.origin_source = nil
      expect(work_package.imported?).to be false
    end
  end

  describe "#origin_link_available?" do
    it "returns true when origin_url is present" do
      work_package.origin_url = "https://jira.example.com/browse/PROJ-123"
      expect(work_package.origin_link_available?).to be true
    end

    it "returns false when origin_url is nil" do
      work_package.origin_url = nil
      expect(work_package.origin_link_available?).to be false
    end

    it "returns false when origin_url is empty" do
      work_package.origin_url = ""
      expect(work_package.origin_link_available?).to be false
    end
  end

  describe ".imported" do
    let!(:imported_wp) do
      create(:work_package,
             origin_source: "jira_data_center",
             origin_id: "123",
             origin_url: "https://jira.example.com/browse/PROJ-123",
             origin_host: "https://jira.example.com")
    end
    let!(:native_wp) { create(:work_package) }

    it "returns only work packages with an origin_source" do
      expect(WorkPackage.imported).to include(imported_wp)
      expect(WorkPackage.imported).not_to include(native_wp)
    end
  end

  describe ".from_source" do
    let!(:jira_wp) do
      create(:work_package,
             origin_source: "jira_data_center",
             origin_id: "123",
             origin_url: "https://jira.example.com/browse/PROJ-123",
             origin_host: "https://jira.example.com")
    end
    let!(:native_wp) { create(:work_package) }

    it "returns work packages from the specified source" do
      expect(WorkPackage.from_source("jira_data_center")).to include(jira_wp)
      expect(WorkPackage.from_source("jira_data_center")).not_to include(native_wp)
    end
  end

  describe ".from_host" do
    let!(:jira_wp1) do
      create(:work_package,
             origin_source: "jira_data_center",
             origin_id: "123",
             origin_url: "https://jira1.example.com/browse/PROJ-123",
             origin_host: "https://jira1.example.com")
    end
    let!(:jira_wp2) do
      create(:work_package,
             origin_source: "jira_data_center",
             origin_id: "456",
             origin_url: "https://jira2.example.com/browse/PROJ-456",
             origin_host: "https://jira2.example.com")
    end

    it "returns work packages from the specified host" do
      expect(WorkPackage.from_host("https://jira1.example.com")).to include(jira_wp1)
      expect(WorkPackage.from_host("https://jira1.example.com")).not_to include(jira_wp2)
    end
  end
end
