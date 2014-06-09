#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe WorkPackage, :type => :model do
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
    subject { work_package.possible_watcher_users.map(&:id) }

    let!(:admin){ FactoryGirl.create(:admin) }
    let!(:anonymous_user){ FactoryGirl.create(:anonymous) }

    shared_context 'non member role has the permission to view work packages' do
      let(:non_member_role) { FactoryGirl.create(:non_member, permissions: [:view_work_packages]) }
    end

    shared_context 'anonymous role has the permission to view work packages' do
      let!(:anonymous_role) { FactoryGirl.create :anonymous_role, permissions: [:view_work_packages] } # 'project granting candidate' for anonymous user
    end

    context 'when it is a public project' do
      before do
        project.update_attributes is_public: true
      end

      it 'contains project members who are allowed to view work packages' do
        users_allowed_to_view_work_packages = project.users.select{ |u| u.allowed_to?(:view_work_packages, project) }
        expect(work_package.possible_watcher_users.sort).to eq(users_allowed_to_view_work_packages.sort)
      end

      xit { is_expected.to include(project_member.id) }
      it { is_expected.not_to include(admin.id) }

      context 'and the non member role has the permission to view work packages' do
        include_context 'non member role has the permission to view work packages'

        it { is_expected.not_to include(non_member_user.id) }
      end

      context 'and the anonymous role has the permission to view work packages' do
        include_context 'anonymous role has the permission to view work packages'

        it { is_expected.not_to include(anonymous_user.id) }
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
        expect(work_package.possible_watcher_users.sort).to eq(users_allowed_to_view_work_packages.sort)
      end

      xit { is_expected.to include(project_member.id) }

      it { is_expected.not_to include(admin.id) }
      it { is_expected.not_to include(non_member_user.id) }
      it { is_expected.not_to include(anonymous_user.id) }
    end
  end

  describe '#watcher_recipients' do
    subject { work_package.watcher_recipients }

    it { is_expected.to include(watching_user.mail) }

    context 'when the permission to view work packages has been removed' do
      before do
        role.remove_permission! :view_work_packages
        work_package.reload
      end

      it { is_expected.not_to include(watching_user.mail) }
    end
  end

  describe '#watched_by?' do
    subject { work_package.watched_by?(watching_user) }

    context 'when the permission to view work packages has been removed' do
      # an existing watcher shouldn't be removed
      before do
        watching_user
        role.remove_permission! :view_work_packages
        work_package.reload
      end

      it { is_expected.to be_truthy }
    end
  end

  context 'notifications' do
    let(:number_of_recipients) { (work_package.recipients | work_package.watcher_recipients).length }

    it 'sends one delayed mail notification for each watcher recipient' do
      UserMailer.stub_chain :work_package_updated, :deliver
      # Ensure notification setting to be set in a way that will trigger e-mails.
      allow(Setting).to receive(:notified_events).and_return(%w(work_package_updated))
      expect(UserMailer).to receive(:work_package_updated).exactly(number_of_recipients).times
      work_package.update_attributes :description => 'Any new description'
    end
  end
end
