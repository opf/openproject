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

RSpec.describe Version do
  subject(:version) { build(:version, name: "Test Version") }

  it { is_expected.to be_valid }

  describe "default values" do
    let(:version) { described_class.new }

    it "sets the status to be open" do
      expect(version.status)
        .to eq "open"
    end
  end

  describe "validations" do
    context "with finish date that is smaller than the start date" do
      before do
        version.start_date = "2013-05-01"
        version.effective_date = "2012-01-01"
      end

      it "is invalid" do
        expect(version).not_to be_valid
        expect(version.errors[:effective_date])
          .to eq [I18n.t("activerecord.errors.messages.greater_than_start_date")]
      end
    end

    context "with an invalid date" do
      before do
        version.start_date = "2013-05-01"
        version.effective_date = "99999-01-01"
      end

      it "is invalid" do
        expect(version).not_to be_valid
        expect(version.errors[:effective_date])
          .to eq [I18n.t("activerecord.errors.messages.not_a_date")]
      end
    end
  end

  describe "#to_s_for_project" do
    let(:other_project) { build(:project) }

    it "returns only the version for the same project" do
      expect(version.to_s_for_project(version.project)).to eq(version.name.to_s)
    end

    it "returns the project name and the version name for a different project" do
      expect(version.to_s_for_project(other_project)).to eq("#{version.project.name} - #{version.name}")
    end
  end

  describe "#systemwide" do
    it "contains the version if it is shared with all projects" do
      version.sharing = "system"
      version.save!

      expect(described_class.systemwide).to contain_exactly(version)
    end

    it "is empty if the version is not shared" do
      version.sharing = "none"
      version.save!

      expect(described_class.systemwide).to be_empty
    end

    it "is empty if the version is shared with the project hierarchy" do
      version.sharing = "hierarchy"
      version.save!

      expect(described_class.systemwide).to be_empty
    end
  end

  describe "#<=>" do
    let(:version1) { build_stubbed(:version) }
    let(:version2) { build_stubbed(:version) }

    it "is 0 if name and project are equal" do
      version1.project = version2.project
      version1.name = version2.name

      expect(version1 <=> version2).to be 0
    end

    it "is -1 if the project name is alphabetically before the other's project name" do
      version1.name = "BBBB"
      version1.project.name = "AAAA"
      version2.name = "AAAA"
      version2.project.name = "BBBB"

      expect(version1 <=> version2).to be -1
    end

    it "is 1 if the project name is alphabetically after the other's project name" do
      version1.name = "AAAA"
      version1.project.name = "BBBB"
      version2.name = "BBBB"
      version2.project.name = "AAAA"

      expect(version1 <=> version2).to be 1
    end

    it "is -1 if the project name is equal and the version's name is alphabetically before the other's name" do
      version1.project.name = version2.project.name
      version1.name = "AAAA"
      version2.name = "BBBB"

      expect(version1 <=> version2).to be -1
    end

    it "is 1 if the project name is equal and the version's name is alphabetically after the other's name" do
      version1.project.name = version2.project.name
      version1.name = "BBBB"
      version2.name = "AAAA"

      expect(version1 <=> version2).to be 1
    end

    it "is 0 if name and project are equal except for case" do
      version1.project.name = version2.project.name.upcase
      version1.name = version2.name.upcase

      expect(version1 <=> version2).to be 0
    end

    it "is -1 if the project name is alphabetically before the other's project name ignoring case" do
      version1.name = "BBBB"
      version1.project.name = "aaaa"
      version2.name = "AAAA"
      version2.project.name = "BBBB"

      expect(version1 <=> version2).to be -1
    end

    it "is 1 if the project name is alphabetically after the other's project name ignoring case" do
      version1.name = "AAAA"
      version1.project.name = "BBBB"
      version2.name = "BBBB"
      version2.project.name = "aaaa"

      expect(version1 <=> version2).to be 1
    end

    it "is -1 if the project name is equal and the version's name is alphabetically before the other's name ignoring case" do
      version1.project.name = version2.project.name
      version1.name = "aaaa"
      version2.name = "BBBB"

      expect(version1 <=> version2).to be -1
    end

    it "is 1 if the project name is equal and the version's name is alphabetically after the other's name ignoring case" do
      version1.project.name = version2.project.name
      version1.name = "BBBB"
      version2.name = "aaaa"

      expect(version1 <=> version2).to be 1
    end
  end

  describe "#projects" do
    let(:grand_parent_project) do
      build(:project, name: "grand_parent_project")
    end
    let(:parent_project) do
      build(:project, parent: grand_parent_project, name: "parent_project")
    end
    let(:sibling_parent_project) do
      build(:project, parent: grand_parent_project, name: "sibling_parent_project")
    end
    let(:child_project) do
      build(:project, parent: parent_project, name: "child_project")
    end
    let(:sibling_project) do
      build(:project, parent: parent_project, name: "sibling_project")
    end
    let(:unrelated_project) do
      build(:project, name: "unrelated_project")
    end

    let(:unshared_version) do
      build(:version, project: parent_project, sharing: "none")
    end
    let(:hierarchy_shared_version) do
      build(:version, project: parent_project, sharing: "hierarchy")
    end
    let(:descendants_shared_version) do
      build(:version, project: parent_project, sharing: "descendants")
    end
    let(:system_shared_version) do
      build(:version, project: parent_project, sharing: "system")
    end
    let(:tree_shared_version) do
      build(:version, project: parent_project, sharing: "tree")
    end

    def save_all_projects
      grand_parent_project.save!
      parent_project.save!
      sibling_parent_project.save!
      child_project.save!
      sibling_project.save!
      unrelated_project.save!
    end

    before do
      save_all_projects
    end

    it "returns a scope" do
      unshared_version.save

      expect(unshared_version.projects).to be_a(ActiveRecord::Relation)
    end

    it "is empty for a new version" do
      expect(described_class.new.projects).to be_empty
    end

    it "returns project the version is defined in for unshared" do
      unshared_version.save

      expect(unshared_version.projects).to contain_exactly(parent_project)
    end

    it "returns all projects the version is shared with (hierarchy)" do
      hierarchy_shared_version.save!

      expect(hierarchy_shared_version.projects).to contain_exactly(grand_parent_project, parent_project, child_project,
                                                                   sibling_project)
    end

    it "returns all projects the version is shared with (descendants)" do
      descendants_shared_version.save!

      expect(descendants_shared_version.projects).to contain_exactly(parent_project, child_project, sibling_project)
    end

    it "returns all projects the version is shared with (tree)" do
      tree_shared_version.save!

      expect(tree_shared_version.projects).to contain_exactly(grand_parent_project, parent_project, sibling_parent_project,
                                                              child_project, sibling_project)
    end

    it "returns all projects the version is shared with (system)" do
      system_shared_version.save!

      expect(system_shared_version.projects).to contain_exactly(grand_parent_project, parent_project, sibling_parent_project,
                                                                child_project, sibling_project, unrelated_project)
    end

    it "returns only the projects for the version although there is a system shared version" do
      unshared_version.save
      system_shared_version.save!

      expect(unshared_version.projects).to contain_exactly(parent_project)
    end
  end

  describe "#estimated_hours" do
    before do
      version.save
    end

    context "without assigned work packages" do
      it "returns 0.0" do
        expect(version.estimated_hours)
          .to eq 0.0
      end
    end

    context "with assigned work packages without estimated hours" do
      let!(:work_package) { create(:work_package, version:) }

      it "returns 0.0" do
        expect(version.estimated_hours)
          .to eq 0.0
      end
    end

    context "with two assigned work packages with estimated hours" do
      let!(:work_package1) { create(:work_package, version:, estimated_hours: 2.5) }
      let!(:work_package2) { create(:work_package, version:, estimated_hours: 5) }

      it "returns the sum of estimated hours" do
        expect(version.estimated_hours)
          .to eq 7.5
      end
    end

    context "with assigned work packages with estimated hours in the leaves" do
      let!(:parent) { create(:work_package, version:) }
      let!(:work_package1) { create(:work_package, parent:, version:, estimated_hours: 2.5) }
      let!(:work_package2) { create(:work_package, parent:, version:, estimated_hours: 5) }

      it "returns the sum of estimated hours" do
        expect(version.estimated_hours)
          .to eq 7.5
      end
    end
  end

  describe "#start_date" do
    context "with a value saved and a work package with its own start_date" do
      let(:version) { create(:version, start_date: "2010-01-05") }
      let!(:work_package) { create(:work_package, version:, start_date: "2010-03-01") }

      it "is the value" do
        expect(version.start_date)
          .to eq Date.parse("2010-01-05")
      end
    end

    context "without a value saved and a work package with its own start_date" do
      let(:version) { create(:version) }
      let!(:work_package) { create(:work_package, version:, start_date: "2010-03-01") }

      it "is nil" do
        expect(version.start_date)
          .to be_nil
      end
    end
  end

  describe "#completed_percent and #closed_percent" do
    create_shared_association_defaults_for_work_package_factory

    let(:project) { create(:project) }
    let(:version) { create(:version, project:) }
    let(:closed_status) { create(:status, is_closed: true) }

    context "without a work package" do
      it "is 0 for completed_percent" do
        expect(version.completed_percent)
          .to eq 0
      end

      it "is 0 for closed_percent" do
        expect(version.closed_percent)
          .to eq 0
      end
    end

    context "with assigned work packages that are not begun" do
      before do
        create(:work_package, version:)
        create(:work_package, version:, done_ratio: 0)
      end

      it "is 0 for completed_percent" do
        expect(version.completed_percent)
          .to eq 0
      end

      it "is 0 for closed_percent" do
        expect(version.closed_percent)
          .to eq 0
      end
    end

    context "with assigned work packages that are closed" do
      before do
        create(:work_package, status: closed_status, version:)
        create(:work_package, status: closed_status, version:, done_ratio: 20)
        create(:work_package, status: closed_status, version:, done_ratio: 70, estimated_hours: 25)
        create(:work_package, status: closed_status, version:, estimated_hours: 15)
      end

      it "is 100 for completed_percent" do
        expect(version.completed_percent)
          .to eq 100
      end

      it "is 100 for closed_percent" do
        expect(version.closed_percent)
          .to eq 100
      end
    end

    context "with assigned work packages that have only done ratio" do
      before do
        create(:work_package, version:)
        create(:work_package, version:, done_ratio: 20)
        create(:work_package, version:, done_ratio: 70)
      end

      it "considers the done ratio of open work packages" do
        expect(version.completed_percent)
          .to eq (0.0 + 20.0 + 70.0) / 3
      end

      it "is 0 for closed_percent" do
        expect(version.closed_percent)
          .to eq 0
      end
    end

    context "with assigned work packages that have only done ratio with one being closed" do
      before do
        create(:work_package, version:)
        create(:work_package, version:, done_ratio: 20)
        create(:work_package, status: closed_status, version:)
      end

      it "considers the done ratio of open work packages" do
        expect(version.completed_percent)
          .to eq (0.0 + 20.0 + 100.0) / 3
      end

      it "is 33 for closed_percent" do
        expect(version.closed_percent)
          .to eq 100.0 / 3
      end
    end

    context "with assigned work packages that have weighted done ratio" do
      before do
        create(:work_package, version:, estimated_hours: 10)
        create(:work_package, version:, done_ratio: 30, estimated_hours: 20)
        create(:work_package, version:, done_ratio: 10, estimated_hours: 40)
        create(:work_package, status: closed_status, version:, estimated_hours: 25)
      end

      it "considers the weighted done ratio of open work packages" do
        expect(version.completed_percent)
          .to eq ((10.0 * 0) + (20.0 * 0.3) + (40 * 0.1) + (25.0 * 1)) / 95.0 * 100
      end

      it "is considers the weighted closed_percent" do
        expect(version.closed_percent)
          .to eq 25.0 / 95.0 * 100
      end
    end

    context "with assigned work packages that have partly weighted done ratio" do
      before do
        create(:work_package, version:, done_ratio: 20)
        create(:work_package, version:, done_ratio: 30, estimated_hours: 10)
        create(:work_package, version:, done_ratio: 10, estimated_hours: 40)
        create(:work_package, status: closed_status, version:)
      end

      it "considers the weighted done ratio of open work packages and uses default weighting if unset" do
        expect(version.completed_percent)
          .to eq ((25.0 * 0.2) + (25.0 * 1) + (10.0 * 0.3) + (40.0 * 0.1)) / 100.0 * 100
      end

      it "is considers the weighted closed_percent using average for the estimated hours" do
        expect(version.closed_percent)
          .to eq 25.0 / 100.0 * 100
      end
    end
  end

  it_behaves_like "acts_as_customizable included" do
    let(:model_instance) { version }
    let(:custom_field) { create(:version_custom_field) }
  end
end
