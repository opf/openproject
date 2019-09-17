#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require File.expand_path('../../support/shared/become_member', __FILE__)

describe Project, type: :model do
  include BecomeMember

  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }

  describe Project::STATUS_ACTIVE do
    it 'equals 1' do
      # spec that STATUS_ACTIVE has the correct value
      expect(Project::STATUS_ACTIVE).to eq(1)
    end
  end

  describe '#active?' do
    it 'is active when :status equals STATUS_ACTIVE' do
      project = FactoryBot.build :project, status: :active
      expect(project).to be_active
    end

    it "is not active when :status doesn't equal STATUS_ACTIVE" do
      project = FactoryBot.build :project, status: :archived
      expect(project).not_to be_active
    end
  end

  context 'when the wiki module is enabled' do
    let(:project) { FactoryBot.create(:project, disable_modules: 'wiki') }

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
    let(:user) { FactoryBot.create(:user) }
    let(:role_add_subproject) { FactoryBot.create(:role, permissions: [:add_subprojects]) }
    let(:role_copy_projects) { FactoryBot.create(:role, permissions: [:edit_project, :copy_projects, :add_project]) }
    let(:parent_project) { FactoryBot.create(:project) }
    let(:project) { FactoryBot.create(:project, parent: parent_project) }
    let!(:subproject_member) do
      FactoryBot.create(:member,
                         user: user,
                         project: project,
                         roles: [role_copy_projects])
    end
    before do
      login_as(user)
    end

    context 'with permission to add subprojects' do
      let!(:member_add_subproject) do
        FactoryBot.create(:member,
                           user: user,
                           project: parent_project,
                           roles: [role_add_subproject])
      end

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
    let(:user) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group) }
    let(:role) { FactoryBot.create(:role) }
    let!(:user_member) do
      FactoryBot.create(:member,
                        principal: user,
                        project: project,
                        roles: [role])
    end
    let!(:group_member) do
      FactoryBot.create(:member,
                        principal: group,
                        project: project,
                        roles: [role])
    end

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
    let(:project) { FactoryBot.create(:project_with_types) }
    let(:type) { project.types.first }
    let(:other_type) { FactoryBot.create(:type) }
    let(:project_work_package) { FactoryBot.create(:work_package, type: type, project: project) }
    let(:other_project) { FactoryBot.create(:project, types: [other_type, type]) }
    let(:other_project_work_package) { FactoryBot.create(:work_package, type: other_type, project: other_project) }

    it 'returns the type used by a work package of the project' do
      project_work_package
      other_project_work_package

      expect(project.types_used_by_work_packages).to match_array [project_work_package.type]
    end
  end

  context '#rolled_up_versions' do
    let!(:project) { FactoryBot.create(:project) }
    let!(:parent_version1) { FactoryBot.create(:version, project: project) }
    let!(:parent_version2) { FactoryBot.create(:version, project: project) }

    it 'should include the versions for the current project' do
      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2]
    end

    it 'should include versions for a subproject' do
      subproject = FactoryBot.create(:project, parent: project)
      subproject_version = FactoryBot.create(:version, project: subproject)

      project.reload

      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2, subproject_version]
    end

    it 'should include versions for a sub-subproject' do
      subproject = FactoryBot.create(:project, parent: project)
      sub_subproject = FactoryBot.create(:project, parent: subproject)
      sub_subproject_version = FactoryBot.create(:version, project: sub_subproject)

      project.reload

      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2, sub_subproject_version]
    end

    it 'should only check active projects' do
      subproject = FactoryBot.create(:project, parent: project)
      FactoryBot.create(:version, project: subproject)
      subproject.archived!

      project.reload

      expect(subproject)
        .not_to be_active
      expect(project.rolled_up_versions)
        .to match_array [parent_version1, parent_version2]
    end
  end

  context '#notified_users' do
    let(:project) { FactoryBot.create(:project) }
    let(:role) { FactoryBot.create(:role) }

    let(:principal) { raise NotImplementedError }
    let(:mail_notification) { false }

    before do
      FactoryBot.create(:member,
                        project: project,
                        principal: principal,
                        roles: [role],
                        mail_notification: mail_notification)
    end

    context 'members with selected mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'selected') }
      let(:mail_notification) { true }

      it 'are included' do
        expect(project.notified_users)
          .to include(principal)
      end
    end

    context 'members with unselected mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'selected') }
      let(:mail_notification) { false }

      it 'are not included' do
        expect(project.notified_users)
          .to be_empty
      end
    end

    context 'members with `all` notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'all') }

      it 'are included' do
        expect(project.notified_users)
          .to include(principal)
      end
    end

    context 'members with `none` mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'none') }

      it 'are not included' do
        expect(project.notified_users)
          .to be_empty
      end
    end

    context 'members with `only_my_events` mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'only_my_events') }

      it 'are not included' do
        expect(project.notified_users)
          .to be_empty
      end
    end

    context 'members with `only_assigned` mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'only_assigned') }

      it 'are not included' do
        expect(project.notified_users)
          .to be_empty
      end
    end

    context 'members with `only_owner` mail notification' do
      let(:principal) { FactoryBot.create(:user, mail_notification: 'only_owner') }

      it 'are not included' do
        expect(project.notified_users)
          .to be_empty
      end
    end
  end
end
