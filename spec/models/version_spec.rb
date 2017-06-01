#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Version, type: :model do
  subject(:version) { FactoryGirl.build(:version, name: 'Test Version') }

  it { is_expected.to be_valid }

  it 'rejects a due date that is smaller than the start date' do
    version.start_date = '2013-05-01'
    version.effective_date = '2012-01-01'

    expect(version).not_to be_valid
    expect(version.errors[:effective_date].size).to eq(1)
  end

  context '#to_s_for_project' do
    let(:other_project) { FactoryGirl.build(:project) }

    it 'returns only the version for the same project' do
      expect(version.to_s_for_project(version.project)).to eq("#{version.name}")
    end

    it 'returns the project name and the version name for a different project' do
      expect(version.to_s_for_project(other_project)).to eq("#{version.project.name} - #{version.name}")
    end
  end

  context 'deprecated methods' do
    it { is_expected.to respond_to :completed_pourcent }
    it { is_expected.to respond_to :closed_pourcent    }
  end

  describe '#systemwide' do
    it 'contains the version if it is shared with all projects' do
      version.sharing = 'system'
      version.save!

      expect(Version.systemwide).to match_array [version]
    end

    it 'is empty if the version is not shared' do
      version.sharing = 'none'
      version.save!

      expect(Version.systemwide).to be_empty
    end

    it 'is empty if the version is shared with the project hierarchy' do
      version.sharing = 'hierarchy'
      version.save!

      expect(Version.systemwide).to be_empty
    end
  end

  context '#<=>' do
    let(:version1) { FactoryGirl.build_stubbed(:version) }
    let(:version2) { FactoryGirl.build_stubbed(:version) }

    it 'is 0 if name and project are equal' do
      version1.project = version2.project
      version1.name = version2.name

      expect(version1 <=> version2).to be 0
    end

    it "is -1 if the project name is alphabetically before the other's project name" do
      version1.name = 'BBBB'
      version1.project.name = 'AAAA'
      version2.name = 'AAAA'
      version2.project.name = 'BBBB'

      expect(version1 <=> version2).to eql -1
    end

    it "is 1 if the project name is alphabetically after the other's project name" do
      version1.name = 'AAAA'
      version1.project.name = 'BBBB'
      version2.name = 'BBBB'
      version2.project.name = 'AAAA'

      expect(version1 <=> version2).to eql 1
    end

    it "is -1 if the project name is equal
        and the version's name is alphabetically before the other's name" do
      version1.project.name = version2.project.name
      version1.name = 'AAAA'
      version2.name = 'BBBB'

      expect(version1 <=> version2).to eql -1
    end

    it "is 1 if the project name is equal
        and the version's name is alphabetically after the other's name" do
      version1.project.name = version2.project.name
      version1.name = 'BBBB'
      version2.name = 'AAAA'

      expect(version1 <=> version2).to eql 1
    end

    it 'is 0 if name and project are equal except for case' do
      version1.project.name = version2.project.name.upcase
      version1.name = version2.name.upcase

      expect(version1 <=> version2).to be 0
    end

    it "is -1 if the project name is alphabetically before the other's project name ignoring case" do
      version1.name = 'BBBB'
      version1.project.name = 'aaaa'
      version2.name = 'AAAA'
      version2.project.name = 'BBBB'

      expect(version1 <=> version2).to eql -1
    end

    it "is 1 if the project name is alphabetically after the other's project name ignoring case" do
      version1.name = 'AAAA'
      version1.project.name = 'BBBB'
      version2.name = 'BBBB'
      version2.project.name = 'aaaa'

      expect(version1 <=> version2).to eql 1
    end

    it "is -1 if the project name is equal
        and the version's name is alphabetically before the other's name ignoring case" do
      version1.project.name = version2.project.name
      version1.name = 'aaaa'
      version2.name = 'BBBB'

      expect(version1 <=> version2).to eql -1
    end

    it "is 1 if the project name is equal
        and the version's name is alphabetically after the other's name ignoring case" do
      version1.project.name = version2.project.name
      version1.name = 'BBBB'
      version2.name = 'aaaa'

      expect(version1 <=> version2).to eql 1
    end
  end

  context '#projects' do
    let(:grand_parent_project) do
      FactoryGirl.build(:project, name: 'grand_parent_project')
    end
    let(:parent_project) do
      FactoryGirl.build(:project, parent: grand_parent_project, name: 'parent_project')
    end
    let(:sibling_parent_project) do
      FactoryGirl.build(:project, parent: grand_parent_project, name: 'sibling_parent_project')
    end
    let(:child_project) do
      FactoryGirl.build(:project, parent: parent_project, name: 'child_project')
    end
    let(:sibling_project) do
      FactoryGirl.build(:project, parent: parent_project, name: 'sibling_project')
    end
    let(:unrelated_project) do
      FactoryGirl.build(:project, name: 'unrelated_project')
    end

    let(:unshared_version) do
      FactoryGirl.build(:version, project: parent_project, sharing: 'none')
    end
    let(:hierarchy_shared_version) do
      FactoryGirl.build(:version, project: parent_project, sharing: 'hierarchy')
    end
    let(:descendants_shared_version) do
      FactoryGirl.build(:version, project: parent_project, sharing: 'descendants')
    end
    let(:system_shared_version) do
      FactoryGirl.build(:version, project: parent_project, sharing: 'system')
    end
    let(:tree_shared_version) do
      FactoryGirl.build(:version, project: parent_project, sharing: 'tree')
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

    it 'returns a scope' do
      unshared_version.save

      expect(unshared_version.projects).to be_a(ActiveRecord::Relation)
    end

    it 'is empty for a new version' do
      expect(Version.new.projects).to be_empty
    end

    it 'returns project the version is defined in for unshared' do
      unshared_version.save

      expect(unshared_version.projects).to match_array([parent_project])
    end

    it 'returns all projects the version is shared with (hierarchy)' do
      hierarchy_shared_version.save!

      expect(hierarchy_shared_version.projects).to match_array([grand_parent_project,
                                                                parent_project,
                                                                child_project,
                                                                sibling_project])
    end

    it 'returns all projects the version is shared with (descendants)' do
      descendants_shared_version.save!

      expect(descendants_shared_version.projects).to match_array([parent_project,
                                                                  child_project,
                                                                  sibling_project])
    end

    it 'returns all projects the version is shared with (tree)' do
      tree_shared_version.save!

      expect(tree_shared_version.projects).to match_array([grand_parent_project,
                                                           parent_project,
                                                           sibling_parent_project,
                                                           child_project,
                                                           sibling_project])
    end

    it 'returns all projects the version is shared with (system)' do
      system_shared_version.save!

      expect(system_shared_version.projects).to match_array([grand_parent_project,
                                                             parent_project,
                                                             sibling_parent_project,
                                                             child_project,
                                                             sibling_project,
                                                             unrelated_project])
    end

    it 'returns only the projects for the version although there is a system shared version' do
      unshared_version.save
      system_shared_version.save!

      expect(unshared_version.projects).to match_array([parent_project])
    end
  end
end
