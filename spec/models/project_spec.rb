#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe Project, type: :model do
  include BecomeMember

  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

  describe Project::STATUS_ACTIVE do
    it 'equals 1' do
      # spec that STATUS_ACTIVE has the correct value
      expect(Project::STATUS_ACTIVE).to eq(1)
    end
  end

  describe '#active?' do
    before do
      # stub out the actual value of the constant
      stub_const('Project::STATUS_ACTIVE', 42)
    end

    it 'is active when :status equals STATUS_ACTIVE' do
      project = FactoryGirl.create :project, status: 42
      expect(project).to be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryGirl.create :project, status: 99
      expect(project).not_to be_active
    end
  end

  describe 'associated_project_candidates' do
    let(:project_type) { FactoryGirl.create(:project_type, allows_association: true) }

    before do
      FactoryGirl.create(:type_standard)
    end

    it 'should not include the project' do
      project.project_type = project_type
      project.save!

      expect(project.associated_project_candidates(admin)).to be_empty
    end
  end

  describe '#find_visible' do
    it 'should find the project by id if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      expect(Project.find_visible(user, project.id)).to eq(project)
    end

    it 'should find the project by identifier if the user is project member' do
      become_member_with_permissions(project, user, :view_work_packages)

      expect(Project.find_visible(user, project.identifier)).to eq(project)
    end

    it 'should not find the project by identifier if the user is no project member' do
      expect { Project.find_visible(user, project.identifier) }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'should not find the project by id if the user is no project member' do
      expect { Project.find_visible(user, project.id) }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  context 'when the wiki module is enabled' do
    let(:project) { FactoryGirl.create(:project, disable_modules: 'wiki') }

    before :each do
      project.enabled_module_names = project.enabled_module_names | ['wiki']
      project.save
      project.reload
    end

    it 'creates a wiki' do
      expect(project.wiki).to be_present
    end

    it 'creates a wiki menu item named like the default start page' do
      expect(project.wiki.wiki_menu_items).to be_one
      expect(project.wiki.wiki_menu_items.first.title).to eq(project.wiki.start_page)
    end
  end

  describe 'copy_allowed?' do
    let(:user) { FactoryGirl.create(:user) }
    let(:role_add_subproject) { FactoryGirl.create(:role, permissions: [:add_subprojects]) }
    let(:role_copy_projects) { FactoryGirl.create(:role, permissions: [:edit_project, :copy_projects, :add_project]) }
    let(:parent_project) { FactoryGirl.create(:project) }
    let(:project) { FactoryGirl.create(:project, parent: parent_project) }
    let!(:subproject_member) {
      FactoryGirl.create(:member,
                         user: user,
                         project: project,
                         roles: [role_copy_projects])
    }
    before do
      login_as(user)
    end

    context 'with permission to add subprojects' do
      let!(:member_add_subproject) {
        FactoryGirl.create(:member,
                           user: user,
                           project: parent_project,
                           roles: [role_add_subproject])
      }

      it 'should allow copy' do
        expect(project.copy_allowed?).to eq(true)
      end
    end

    context 'with permission to add subprojects' do
      it 'should not allow copy' do
        expect(project.copy_allowed?).to eq(false)
      end
    end
  end

  describe 'available principles' do
    let(:user) { FactoryGirl.create(:user) }
    let(:group) { FactoryGirl.create(:group) }
    let(:role) { FactoryGirl.create(:role) }
    let!(:user_member) {
      FactoryGirl.create(:member,
                         principal: user,
                         project: project,
                         roles: [role])
    }
    let!(:group_member) {
      FactoryGirl.create(:member,
                         principal: group,
                         project: project,
                         roles: [role])
    }

    shared_examples_for 'respecting group assignment settings' do
      context 'with group assignment' do
        before { allow(Setting).to receive(:work_package_group_assignment?).and_return(true) }

        it { is_expected.to match_array([user, group]) }
      end

      context 'w/o group assignment' do
        before { allow(Setting).to receive(:work_package_group_assignment?).and_return(false) }

        it { is_expected.to match_array([user]) }
      end
    end

    describe 'assignees' do
      subject { project.possible_assignees }

      it_behaves_like 'respecting group assignment settings'
    end

    describe 'responsibles' do
      subject { project.possible_responsibles }

      it_behaves_like 'respecting group assignment settings'
    end
  end

  describe '#types_used_by_work_packages' do
    let(:project) { FactoryGirl.create(:project_with_types) }
    let(:type) { project.types.first }
    let(:other_type) { project.types.second }
    let(:project_work_package) { FactoryGirl.create(:work_package, type: type, project: project) }
    let(:other_project_work_package) { FactoryGirl.create(:work_package, type: other_type) }

    it 'returns the type used by a work package of the project' do
      project_work_package
      other_project_work_package

      expect(project.types_used_by_work_packages).to match_array [project_work_package.type]
    end
  end
end
