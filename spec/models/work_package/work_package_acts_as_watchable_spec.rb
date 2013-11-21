#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe WorkPackage do
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) { FactoryGirl.create(:work_package,
                                          project: project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }

  let(:non_member_user) { FactoryGirl.create(:user) }
  let(:project_member) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let!(:watching_user) do
    FactoryGirl.create(:user, member_in_project: project, member_through_role: role).tap {|user| Watcher.create(watchable: work_package, user: user)}
  end

  describe '#possible_watcher_users' do
    subject { work_package.possible_watcher_users }

    let!(:admin){ FactoryGirl.create(:admin) }
    let!(:anonymous_user){ FactoryGirl.create(:anonymous) }

    shared_context 'non member role has the permission to view work packages' do
      let(:non_member_role) { Role.find_by_name('Non member') }

      before do
        non_member_role.add_permission! :view_work_packages
      end
    end

    shared_context 'anonymous role has the permission to view work packages' do
      let!(:anonymous_role) { FactoryGirl.create :anonymous_role, permissions: [:view_work_packages] } # 'project granting candidate' for anonymous user
    end

    context 'when it is a public project' do
      it 'contains non-anonymous users who are allowed to view work packages' do
        users_allowed_to_view_work_packages = User.not_builtin.select{ |u| u.allowed_to?(:view_work_packages, project) }
        work_package.possible_watcher_users.sort.should == users_allowed_to_view_work_packages.sort
      end

      it { should include(admin) }
      it { should include(project_member) }

      context 'and the non member role has the permission to view work packages' do
        include_context 'non member role has the permission to view work packages'

        it { should include(non_member_user) }
      end

      context 'and the anonymous role has the permission to view work packages' do
        include_context 'anonymous role has the permission to view work packages'

        it { should_not include(anonymous_user) }
      end
    end

    context 'when it is a private project' do
      include_context 'non member role has the permission to view work packages'
      include_context 'anonymous role has the permission to view work packages'

      before do
        project.update_attributes is_public: false
        work_package.reload
      end

      it 'contains project members who are allowed to view work packages' do
        users_allowed_to_view_work_packages = project.users.select{ |u| u.allowed_to?(:view_work_packages, project) }
        work_package.possible_watcher_users.sort.should == users_allowed_to_view_work_packages.sort
      end

      it { should include(project_member) }

      it { should_not include(admin) }
      it { should_not include(non_member_user) }
      it { should_not include(anonymous_user) }
    end
  end

  describe '#watcher_recipients' do
    subject { work_package.watcher_recipients }

    it { should include(watching_user.mail) }

    context 'when the permission to view work packages has been removed' do
      before do
        role.remove_permission! :view_work_packages
        work_package.reload
      end

      it { should_not include(watching_user.mail) }
    end
  end

  describe '#watched_by?' do
    subject { work_package.watched_by?(watching_user) }

    context 'when the permission to view work packages has been removed' do
      # an existing watcher shouldn't be removed
      before do
        role.remove_permission! :view_work_packages
        work_package.reload
      end

      it { should be_true }
    end
  end

  context 'notifications' do
    let(:number_of_recipients) { (work_package.recipients | work_package.watcher_recipients).length }

    before :each do
      Delayed::Worker.delay_jobs = false
    end

    it 'sends one delayed mail notification for each watcher recipient' do
      UserMailer.stub_chain :issue_updated, :deliver
      UserMailer.should_receive(:issue_updated).exactly(number_of_recipients).times
      work_package.update_attributes :description => 'Any new description'
    end
  end
end
