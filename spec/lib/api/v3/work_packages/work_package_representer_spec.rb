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

  let(:representer)  { described_class.new(work_package, current_user: current_user) }

  let(:work_package) {
    FactoryGirl.build(:work_package,
                      id: 42,
                      created_at: DateTime.now,
                      updated_at: DateTime.now,
                      category:   category,
                      done_ratio: 50,
                      estimated_hours: 6.0)
  }
  let(:category) { FactoryGirl.build(:category) }
  let(:project) { work_package.project }
  let(:permissions) {
    [
      :view_work_packages,
      :view_work_package_watchers,
      :edit_work_packages,
      :add_work_package_watchers,
      :delete_work_package_watchers,
      :manage_work_package_relations,
      :add_work_package_notes
    ]
  }
  let(:role) { FactoryGirl.create :role, permissions: permissions }

  before(:each) do
    allow(User).to receive(:current).and_return current_user
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { is_expected.to have_json_path('id') }

      it { is_expected.to have_json_path('description') }
      it { is_expected.to have_json_path('rawDescription') }

      it { is_expected.to have_json_path('dueDate') }

      it { is_expected.to have_json_path('percentageDone') }
      it { is_expected.to have_json_path('priority') }

      it { is_expected.to have_json_path('projectId') }
      it { is_expected.to have_json_path('projectName') }

      it { is_expected.to have_json_path('startDate') }
      it { is_expected.to have_json_path('status') }
      it { is_expected.to have_json_path('subject') }
      it { is_expected.to have_json_path('type') }

      it { is_expected.to have_json_path('createdAt') }
      it { is_expected.to have_json_path('updatedAt') }

      it { is_expected.to have_json_path('isClosed') }

      describe 'version' do
        it { is_expected.to have_json_path('versionId') }
        it { is_expected.to have_json_path('versionName') }
      end

      describe 'lock version' do
        it { is_expected.to have_json_path('lockVersion') }

        it { is_expected.to have_json_type(Integer).at_path('lockVersion') }

        it { is_expected.to be_json_eql(work_package.lock_version.to_json).at_path('lockVersion') }
      end
    end

    describe 'estimatedTime' do
      let(:work_package) {
        FactoryGirl.build(:work_package,
                          id: 42,
                          created_at: DateTime.now,
                          updated_at: DateTime.now,
                          estimated_hours: 6.5)
      }

      it { is_expected.to be_json_eql('PT6H30M'.to_json).at_path('estimatedTime') }
    end

    describe 'spentTime' do
      before { permissions << :view_time_entries }

      describe :content do
        let(:wp) { FactoryGirl.create(:work_package) }
        let(:permissions) { [:view_work_packages, :view_time_entries] }
        let(:role) { FactoryGirl.create(:role, permissions: permissions) }
        let(:user) {
          FactoryGirl.create(:user,
                             member_in_project: wp.project,
                             member_through_role: role)
        }
        let(:representer)  { described_class.new(wp, current_user: user) }

        before do
          allow(User).to receive(:current).and_return(user)

          allow(user).to receive(:allowed_to?).and_return(false)
          allow(user).to receive(:allowed_to?).with(:view_time_entries, anything)
                                              .and_return(true)
        end

        context 'no view_time_entries permission' do
          before do
            allow(user).to receive(:allowed_to?).with(:view_time_entries, anything)
                                                .and_return(false)

          end

          it { is_expected.to_not have_json_path('spentTime') }
        end

        context 'no time entry' do
          it { is_expected.to be_json_eql('PT0S'.to_json).at_path('spentTime') }
        end

        context 'time entry with single hour' do
          let(:time_entry) {
            FactoryGirl.create(:time_entry,
                               project: wp.project,
                               work_package: wp,
                               hours: 1.0)
          }

          before { time_entry }

          it { is_expected.to be_json_eql('PT1H'.to_json).at_path('spentTime') }
        end

        context 'time entry with multiple hours' do
          let(:time_entry) {
            FactoryGirl.create(:time_entry,
                               project: wp.project,
                               work_package: wp,
                               hours: 42.5)
          }

          before { time_entry }

          it { is_expected.to be_json_eql('P1DT18H30M'.to_json).at_path('spentTime') }
        end
      end
    end

    describe 'percentageDone' do
      describe 'work package done ratio setting behavior' do
        context 'setting enabled' do
          it { expect(parse_json(subject)['percentageDone']).to eq(50) }
        end

        context 'setting disabled' do
          before { allow(Setting).to receive(:work_package_done_ratio).and_return('disabled') }

          it { expect(parse_json(subject)['percentageDone']).to be_nil }
        end
      end
    end

    describe '_links' do
      it { is_expected.to have_json_type(Object).at_path('_links') }

      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
        expect(subject).to have_json_path('_links/self/title')
      end

      describe 'update links' do
        describe 'update by form' do
          it { expect(subject).to have_json_path('_links/update/href') }
          it {
            expect(subject).to be_json_eql("/api/v3/work_packages/#{work_package.id}/form".to_json)
              .at_path('_links/update/href')
          }
          it { expect(subject).to be_json_eql('post'.to_json).at_path('_links/update/method') }
        end

        describe 'immediate update' do
          it { expect(subject).to have_json_path('_links/updateImmediately/href') }
          it {
            expect(subject).to be_json_eql("/api/v3/work_packages/#{work_package.id}".to_json)
              .at_path('_links/updateImmediately/href')
          }
          it {
            expect(subject).to be_json_eql('patch'.to_json)
              .at_path('_links/updateImmediately/method')
          }
        end
      end

      describe 'version' do
        context 'no version set' do
          it { is_expected.to_not have_json_path('versionViewable') }
        end

        context 'version set' do
          let!(:version) { FactoryGirl.create :version, project: project }
          before do
            work_package.fixed_version = version
          end

          it { is_expected.to have_json_path('_links/version/href') }

          context ' but is not accessible due to permissions' do
            before do
              current_user.stub(:allowed_to?).and_call_original
              current_user.stub(:allowed_to?).with({ controller: 'versions', action: 'show' }, project, global: false).and_return(false)
            end

            it { is_expected.to_not have_json_path('_links/version/href') }
          end
        end
      end

      context 'when the user has the permission to view work packages' do
        context 'and the user is not watching the work package' do
          it 'should have a link to watch' do
            expect(subject).to have_json_path('_links/watchChanges/href')
          end

          it 'should not have a link to unwatch' do
            expect(subject).to_not have_json_path('_links/unwatchChanges/href')
          end
        end

        context 'and the user is watching the work package' do
          before do
            work_package.watcher_users << current_user
          end

          it 'should have a link to watch' do
            expect(subject).to have_json_path('_links/unwatchChanges/href')
          end

          it 'should not have a link to watch' do
            expect(subject).to_not have_json_path('_links/watchChanges/href')
          end
        end
      end

      context 'and the user does not have the permission to view work packages' do
        let(:current_user) { FactoryGirl.create :user }

        it 'should not have a link to unwatch' do
          expect(subject).to_not have_json_path('_links/unwatchChanges/href')
        end

        it 'should not have a link to watch' do
          expect(subject).to_not have_json_path('_links/watchChanges/href')
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

      context 'when the user has the permission to add work packages' do
        before do
          role.permissions.push(:add_work_packages) and role.save
        end
        it 'should have a link to add child' do
          expect(subject).to have_json_path('_links/addChild/href')
        end
      end

      context 'when the user does not have the permission to add work packages' do
        before do
          role.permissions.delete(:add_work_packages) and role.save
        end
        it 'should not have a link to add child' do
          expect(subject).to_not have_json_path('_links/addChild/href')
        end
      end

      context 'when the user has the permission to view time entries' do
        before do
          role.permissions.push(:view_time_entries) and role.save
        end
        it 'should have a link to add child' do
          expect(subject).to have_json_path('_links/timeEntries/href')
        end
      end

      context 'when the user does not have the permission to view time entries' do
        before do
          role.permissions.delete(:view_time_entries) and role.save
        end
        it 'should not have a link to timeEntries' do
          expect(subject).to_not have_json_path('_links/timeEntries/href')
        end
      end

      describe 'linked relations' do
        let(:project) { FactoryGirl.create(:project, is_public: false) }
        let(:forbidden_project) { FactoryGirl.create(:project, is_public: false) }
        let(:user) { FactoryGirl.create(:user, member_in_project: project) }

        before do
          allow(User).to receive(:current).and_return(user)
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        context 'parent' do
          let(:work_package) {
            FactoryGirl.create(:work_package,
                               project: project,
                               parent_id: forbidden_work_package.id)
          }
          let!(:forbidden_work_package) { FactoryGirl.create(:work_package, project: forbidden_project) }

          it { expect(subject).to_not have_json_path('_links/parent') }
        end

        context 'children' do
          let(:work_package) { FactoryGirl.create(:work_package, project: project) }
          let!(:forbidden_work_package) {
            FactoryGirl.create(:work_package,
                               project: forbidden_project,
                               parent_id: work_package.id)
          }

          it { expect(subject).to_not have_json_path('_links/children') }

          describe 'visible and invisible children' do
            let!(:child) {
              FactoryGirl.create(:work_package,
                                 project: project,
                                 parent_id: work_package.id)
            }

            it { expect(subject).to have_json_size(1).at_path('_links/children') }

            it { expect(parse_json(subject)['_links']['children'][0]['title']).to eq(child.subject) }
          end
        end
      end

      describe 'delete' do
        it_behaves_like 'action link' do
          let(:action) { 'delete' }
          let(:permission) { :delete_work_packages }
        end
      end

      describe 'log_time' do
        it_behaves_like 'action link' do
          let(:action) { 'log_time' }
          let(:permission) { :log_time }
        end
      end

      describe 'duplicate' do
        it_behaves_like 'action link' do
          let(:action) { 'duplicate' }
          let(:permission) { :add_work_packages }
        end
      end

      describe 'move' do
        it_behaves_like 'action link' do
          let(:action) { 'move' }
          let(:permission) { :move_work_packages }
        end
      end

      describe 'changeParent' do
        it_behaves_like 'action link' do
          let(:action) { 'changeParent' }
          let(:permission) { :manage_subtasks }
        end
      end
    end

    describe '_embedded' do
      it { is_expected.to have_json_type(Object).at_path('_embedded') }

      describe 'activities' do
        it { is_expected.to have_json_type(Array).at_path('_embedded/activities') }
        it { is_expected.to have_json_size(0).at_path('_embedded/activities') }
      end

      describe 'attachments' do
        it { is_expected.to have_json_type(Array).at_path('_embedded/attachments') }
        it { is_expected.to have_json_size(0).at_path('_embedded/attachments') }
      end

      describe 'watchers' do
        context 'when the current user has the permission to view work packages' do
          it { is_expected.to have_json_path('_embedded/watchers') }
        end

        context 'when the current user does not have the permission to view work packages' do
          before do
            role.permissions.delete(:view_work_package_watchers) and role.save
          end

          it { is_expected.not_to have_json_path('_embedded/watchers') }
        end
      end

      describe 'category' do
        it { is_expected.to have_json_type(Hash).at_path('_embedded/category') }
        it { is_expected.to be_json_eql(%{Category}.to_json).at_path('_embedded/category/_type') }
      end
    end
  end
end
