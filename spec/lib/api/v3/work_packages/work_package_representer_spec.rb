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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  let(:member) { FactoryGirl.create(:user,  member_in_project: project, member_through_role: role) }
  let(:current_user) { member }

  let(:representer)  { described_class.new(model, current_user: current_user) }

  let(:model)        { ::API::V3::WorkPackages::WorkPackageModel.new(
      work_package: work_package
    )
  }
  let(:work_package) { FactoryGirl.build(:work_package,
      created_at: DateTime.now,
      updated_at: DateTime.now
    )
  }
  let(:project) { work_package.project }
  let(:permissions) { %i(view_work_packages view_work_package_watchers add_work_package_watchers delete_work_package_watchers manage_work_package_relations add_work_package_notes) }
  let(:role) { FactoryGirl.create :role, permissions: permissions }

  before(:each) do
    allow(User).to receive(:current).and_return current_user
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { should have_json_path('id') }

      it { should have_json_path('description') }
      it { should have_json_path('rawDescription') }

      it { should have_json_path('dueDate') }

      it { should have_json_path('percentageDone') }
      it { should have_json_path('priority') }

      it { should have_json_path('projectId') }
      it { should have_json_path('projectName') }

      it { should have_json_path('startDate') }
      it { should have_json_path('status') }
      it { should have_json_path('subject') }
      it { should have_json_path('type') }

      it { should have_json_path('versionId') }
      it { should have_json_path('versionName') }

      it { should have_json_path('createdAt') }
      it { should have_json_path('updatedAt') }

      it { should have_json_path('isClosed') }
    end

    describe 'estimatedTime' do
      it { should have_json_type(Object).at_path('estimatedTime') }

      it { should have_json_path('estimatedTime/units') }
      it { should have_json_path('estimatedTime/value') }
    end

    describe '_links' do
      it { should have_json_type(Object).at_path('_links') }

      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
        expect(subject).to have_json_path('_links/self/title')
      end

      context 'when the user has the permission to view work packages' do
        context 'and the user is not watching the work package' do
          it 'should have a link to watch' do
            expect(subject).to have_json_path('_links/watch/href')
          end

          it 'should not have a link to unwatch' do
            expect(subject).to_not have_json_path('_links/unwatch/href')
          end
        end

        context 'and the user is watching the work package' do
          before do
            work_package.watcher_users << current_user
          end

          it 'should have a link to watch' do
            expect(subject).to have_json_path('_links/unwatch/href')
          end

          it 'should not have a link to watch' do
            expect(subject).to_not have_json_path('_links/watch/href')
          end
        end
      end

      context 'and the user does not have the permission to view work packages' do
        let(:current_user) { FactoryGirl.create :user }

        it 'should not have a link to unwatch' do
          expect(subject).to_not have_json_path('_links/unwatch/href')
        end

        it 'should not have a link to watch' do
          expect(subject).to_not have_json_path('_links/watch/href')
        end
      end

      context 'when the user has permission to add comments' do
        it 'should have a link to add comment' do
          expect(subject).to have_json_path('_links/addComment')
        end
      end

      context 'when the user does not have the permission to add comments' do
        before do
          role.permissions.delete(:add_work_package_notes) and role.save
        end

        it 'should not have a link to add comment' do
          expect(subject).to_not have_json_path('_links/addComment/href')
        end
      end

      context 'when the user has the permission to add and remove watchers' do
        it 'should have a link to add watcher' do
          expect(subject).to have_json_path('_links/addWatcher/href')
        end
      end

      context 'when the user does not have the permission to add watchers' do
        before do
          role.permissions.delete(:add_work_package_watchers) and role.save
        end

        it 'should not have a link to add watcher' do
          expect(subject).to_not have_json_path('_links/addWatcher/href')
        end
      end

      context 'when the user has the permission to manage relations' do
        it 'should have a link to add relation' do
          expect(subject).to have_json_path('_links/addRelation/href')
        end
      end

      context 'when the user does not have the permission to manage relations' do
        before do
          role.permissions.delete(:manage_work_package_relations) and role.save
        end

        it 'should not have a link to add relation' do
          expect(subject).to_not have_json_path('_links/addRelation/href')
        end
      end

      context 'parent' do
        let(:project) { FactoryGirl.create(:project, is_public: false) }
        let(:forbidden_project) { FactoryGirl.create(:project, is_public: false) }
        let(:user) { FactoryGirl.create(:user, member_in_project: project) }

        let(:work_package) { FactoryGirl.create(:work_package,
                                                project: project,
                                                parent_id: forbidden_work_package.id) }
        let(:forbidden_work_package) { FactoryGirl.create(:work_package, project: forbidden_project) }

        before do
          allow(User).to receive(:current).and_return(user)
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        it { expect(subject).to_not have_json_path('_links/parent') }
      end
    end

    describe '_embedded' do
      it { should have_json_type(Object).at_path('_embedded') }

      describe 'activities' do
        it { should have_json_type(Array).at_path('_embedded/activities') }
        it { should have_json_size(0).at_path('_embedded/activities') }
      end

      describe 'attachments' do
        it { should have_json_type(Array).at_path('_embedded/attachments') }
        it { should have_json_size(0).at_path('_embedded/attachments') }
      end

      describe 'watchers' do
        context 'when the current user has the permission to view work packages' do
          it { should have_json_path('_embedded/watchers') }
        end

        context 'when the current user does not have the permission to view work packages' do
          before do
            role.permissions.delete(:view_work_package_watchers) and role.save
          end

          it { should_not have_json_path('_embedded/watchers') }
        end
      end
    end
  end
end
