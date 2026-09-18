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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraCreateProjectVersionsJob,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with jira project import data"

  let!(:jira_version) do
    create(:jira_version,
           jira_import:,
           jira_project:,
           origin_id: "10001",
           payload: {
             "id" => "10001",
             "name" => "v1.0",
             "description" => "First release",
             "releaseDate" => "2025-06-15",
             "startDate" => "2025-01-01",
             "released" => true
           })
  end

  before do
    create_project
  end

  def create_versions
    described_class.perform_now(jira_import.id, jira_project.id)
  end

  describe "#perform" do
    it "creates Version records for each JiraVersion" do
      expect { create_versions }.to change(Version, :count).by(1)
    end

    it "creates versions with correct attributes" do
      create_versions

      version = Version.find_by(name: "v1.0")
      expect(version).to be_present
      expect(version.project.identifier).to eq(jira_project_key)
      expect(version.description).to eq("First release")
      expect(version.effective_date).to eq(Date.parse("2025-06-15"))
      expect(version.start_date).to eq(Date.parse("2025-01-01"))
      expect(version.status).to eq("closed")
    end

    it "creates references for versions" do
      create_versions

      expect(Import::JiraOpenProjectReference.find_op_leg(jira_version)).to be_a(Version)
    end

    context "when version is not released" do
      let!(:jira_version) do
        create(:jira_version,
               jira_import:,
               jira_project:,
               origin_id: "10001",
               payload: { "id" => "10001", "name" => "v1.0", "released" => false })
      end

      it "creates version with open status" do
        create_versions

        version = Version.find_by(name: "v1.0")
        expect(version.status).to eq("open")
      end
    end

    context "when optional fields are missing" do
      let!(:jira_version) do
        create(:jira_version,
               jira_import:,
               jira_project:,
               origin_id: "10001",
               payload: { "id" => "10001", "name" => "v1.0", "released" => false })
      end

      it "creates version with nil for optional fields" do
        create_versions

        version = Version.find_by(name: "v1.0")
        expect(version.description).to be_nil
        expect(version.effective_date).to be_nil
        expect(version.start_date).to be_nil
      end
    end

    context "with multiple versions" do
      let!(:jira_version2) do
        create(:jira_version,
               jira_import:,
               jira_project:,
               origin_id: "10002",
               payload: { "id" => "10002", "name" => "v2.0", "released" => false })
      end

      it "creates all versions" do
        expect { create_versions }.to change(Version, :count).by(2)
      end
    end

    context "when the import is aborting" do
      before do
        # rubocop:disable-next RSpec/AnyInstance
        allow_any_instance_of(Import::JiraImport)
          .to receive(:in_state?).with(:import_aborting).and_return(true)
      end

      it "stops iterating and reports the abortion" do
        expect { create_versions }.to raise_error(Import::ProgressableJob::AbortionError)
      end
    end
  end
end
