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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:member) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:current_user) { member }
  let(:embed_links) { true }
  let(:representer) {
    described_class.create(work_package, current_user: current_user, embed_links: embed_links)
  }

  let(:work_package) {
    FactoryGirl.build(:work_package,
                      id: 42,
                      start_date: Date.today.to_datetime,
                      due_date: Date.today.to_datetime,
                      created_at: DateTime.now,
                      updated_at: DateTime.now,
                      done_ratio: 50,
                      estimated_hours: 6.0)
  }
  let(:project) { work_package.project }
  let(:all_permissions) {
    [
      :view_work_packages,
      :view_work_package_watchers,
      :edit_work_packages,
      :add_work_package_watchers,
      :delete_work_package_watchers,
      :manage_work_package_relations,
      :add_work_package_notes,
      :add_work_packages,
      :view_time_entries,
      :view_changesets,
      :delete_work_packages
    ]
  }
  let(:permissions) { all_permissions }
  let(:role) { FactoryGirl.create :role, permissions: permissions }

  before(:each) do
    allow(User).to receive(:current).and_return current_user
  end

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { is_expected.to have_json_path('id') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'textile' }
        let(:raw) { work_package.description }
        let(:html) { '<p>' + work_package.description + '</p>' }
      end

      it { is_expected.to have_json_path('percentageDone') }

      describe 'startDate' do
        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { work_package.start_date }
          let(:json_path) { 'startDate' }
        end

        context 'no start date' do
          let(:work_package) { FactoryGirl.build(:work_package, id: 42, start_date: nil) }

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('startDate')
          end
        end

        context 'when the work package has a milestone type' do
          let(:milestone_type) {
            FactoryGirl.build_stubbed(:type,
                                      is_milestone: true)
          }

          before do
            work_package.type = milestone_type
          end

          it 'has no startDate' do
            is_expected.to_not have_json_path('startDate')
          end
        end
      end

      describe 'dueDate' do
        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { work_package.due_date }
          let(:json_path) { 'dueDate' }
        end

        context 'no due date' do
          let(:work_package) { FactoryGirl.build(:work_package, id: 42, due_date: nil) }

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('dueDate')
          end
        end

        context 'when the work package has a milestone type' do
          let(:milestone_type) {
            FactoryGirl.build_stubbed(:type,
                                      is_milestone: true)
          }

          before do
            work_package.type = milestone_type
          end

          it 'has no startDate' do
            is_expected.to_not have_json_path('dueDate')
          end
        end
      end

      describe 'date' do
        let(:milestone_type) {
          FactoryGirl.build_stubbed(:type,
                                    is_milestone: true)
        }

        before do
          work_package.type = milestone_type
        end

        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { work_package.due_date } # could just as well be start_date
          let(:json_path) { 'date' }
        end

        context 'no due date' do
          before do
            work_package.due_date = nil
          end

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('date')
          end
        end

        context 'when the work package has a non milestone type' do
          let(:none_milestone_type) {
            FactoryGirl.build_stubbed(:type,
                                      is_milestone: false)
          }

          before do
            work_package.type = none_milestone_type
          end

          it 'has no date' do
            is_expected.to_not have_json_path('date')
          end
        end
      end

      describe 'createdAt' do
        it_behaves_like 'has UTC ISO 8601 date and time' do
          let(:date) { work_package.created_at }
          let(:json_path) { 'createdAt' }
        end
      end

      describe 'updatedAt' do
        it_behaves_like 'has UTC ISO 8601 date and time' do
          let(:date) { work_package.updated_at }
          let(:json_path) { 'updatedAt' }
        end
      end

      it { is_expected.to have_json_path('subject') }

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
      describe '#content' do
        context 'no view_time_entries permission' do
          let(:permissions) { all_permissions - [:view_time_entries] }

          it { is_expected.not_to have_json_path('spentTime') }
        end

        context 'no time entry' do
          it { is_expected.to be_json_eql('PT0S'.to_json).at_path('spentTime') }
        end

        context 'time entry with single hour' do
          before do
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 1.0)
          end

          it { is_expected.to be_json_eql('PT1H'.to_json).at_path('spentTime') }
        end

        context 'time entry with multiple hours' do
          before do
            FactoryGirl.create(:time_entry,
                               project: work_package.project,
                               work_package: work_package,
                               hours: 42.5)
          end

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
          before do allow(Setting).to receive(:work_package_done_ratio).and_return('disabled') end

          it { is_expected.to_not have_json_path('percentageDone') }
        end
      end
    end

    describe 'custom fields' do
      it 'uses a CustomFieldInjector' do
        expect(::API::V3::Utilities::CustomFieldInjector).to receive(:create_value_representer)
          .and_call_original
        representer.to_json
      end
    end

    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { "/api/v3/work_packages/#{work_package.id}" }
        let(:title) { work_package.subject }
      end

      describe 'update links' do
        describe 'update by form' do
          it_behaves_like 'has an untitled link' do
            let(:link) { 'update' }
            let(:href) { api_v3_paths.work_package_form(work_package.id) }
          end

          it 'is a post link' do
            is_expected.to be_json_eql('post'.to_json).at_path('_links/update/method')
          end
        end

        describe 'immediate update' do
          it_behaves_like 'has an untitled link' do
            let(:link) { 'updateImmediately' }
            let(:href) { api_v3_paths.work_package(work_package.id) }
          end

          it 'is a patch link' do
            is_expected.to be_json_eql('patch'.to_json).at_path('_links/updateImmediately/method')
          end
        end

        context 'user is not allowed to edit work packages' do
          let(:permissions) { all_permissions - [:edit_work_packages] }

          it_behaves_like 'has no link' do
            let(:link) { 'update' }
          end

          it_behaves_like 'has no link' do
            let(:link) { 'updateImmediately' }
          end
        end
      end

      describe 'status' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'status' }
          let(:href) { "/api/v3/statuses/#{work_package.status_id}" }
          let(:title) { work_package.status.name }
        end
      end

      describe 'type' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'type' }
          let(:href) { "/api/v3/types/#{work_package.type_id}" }
          let(:title) { work_package.type.name }
        end
      end

      describe 'author' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'author' }
          let(:href) { "/api/v3/users/#{work_package.author.id}" }
          let(:title) { work_package.author.name }
        end
      end

      describe 'assignee' do
        context 'assignee is set' do
          let(:work_package) {
            FactoryGirl.build(:work_package, id: 42, assigned_to: FactoryGirl.build_stubbed(:user))
          }

          it_behaves_like 'has a titled link' do
            let(:link) { 'assignee' }
            let(:href) { "/api/v3/users/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context 'assignee is not set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'assignee' }
          end
        end
      end

      describe 'responsible' do
        context 'responsible is set' do
          let(:work_package) {
            FactoryGirl.build(:work_package, id: 42, responsible: FactoryGirl.build_stubbed(:user))
          }

          it_behaves_like 'has a titled link' do
            let(:link) { 'responsible' }
            let(:href) { "/api/v3/users/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context 'responsible is not set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'responsible' }
          end
        end
      end

      describe 'revisions' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'revisions' }
          let(:href) {
            api_v3_paths.work_package_revisions(work_package.id)
          }
        end
      end

      describe 'version' do
        let(:embedded_path) { '_embedded/version' }
        let(:href_path) { '_links/version/href' }

        context 'no version set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'version' }
          end
        end

        context 'version set' do
          let!(:version) { FactoryGirl.create :version, project: project }

          before do
            work_package.fixed_version = version
          end

          it_behaves_like 'has a titled link' do
            let(:link) { 'version' }
            let(:href) { api_v3_paths.version(version.id) }
            let(:title) { version.to_s }
          end

          it 'has the version embedded' do
            is_expected.to be_json_eql('Version'.to_json).at_path("#{embedded_path}/_type")
            is_expected.to be_json_eql(version.name.to_json).at_path("#{embedded_path}/name")
          end
        end
      end

      describe 'project' do
        let(:embedded_path) { '_embedded/project' }
        let(:href_path) { '_links/project/href' }

        it_behaves_like 'has a titled link' do
          let(:link) { 'project' }
          let(:href) { api_v3_paths.project(project.id) }
          let(:title) { project.name }
        end

        it 'has the project embedded' do
          is_expected.to be_json_eql('Project'.to_json).at_path("#{embedded_path}/_type")
          is_expected.to be_json_eql(project.name.to_json).at_path("#{embedded_path}/name")
        end
      end

      describe 'category' do
        let(:embedded_path) { '_embedded/category' }
        let(:href_path) { '_links/category/href' }

        context 'no category set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'category' }
          end
        end

        context 'category set' do
          let!(:category) { FactoryGirl.create :category, project: project }

          before do
            work_package.category = category
          end

          it_behaves_like 'has a titled link' do
            let(:link) { 'category' }
            let(:href) { api_v3_paths.category(category.id) }
            let(:title) { category.name }
          end

          it 'has the category embedded' do
            is_expected.to have_json_type(Hash).at_path('_embedded/category')
            is_expected.to be_json_eql('Category'.to_json).at_path("#{embedded_path}/_type")
            is_expected.to be_json_eql(category.name.to_json).at_path("#{embedded_path}/name")
          end
        end
      end

      describe 'priority' do
        let(:priority) { work_package.priority }

        it_behaves_like 'has a titled link' do
          let(:link) { 'priority' }
          let(:href) { api_v3_paths.priority(priority.id) }
          let(:title) { priority.name }
        end

        it 'has the priority embedded' do
          is_expected.to be_json_eql('Priority'.to_json).at_path('_embedded/priority/_type')
          is_expected.to be_json_eql(priority.name.to_json).at_path('_embedded/priority/name')
        end
      end

      describe 'schema' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'schema' }
          let(:href) {
            api_v3_paths.work_package_schema(work_package.project.id, work_package.type.id)
          }
        end
      end

      describe 'attachments' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'attachments' }
          let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
        end

        it 'embeds the attachments as collection' do
          is_expected.to be_json_eql('Collection'.to_json).at_path('_embedded/attachments/_type')
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'addAttachment' }
          let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
        end

        it 'addAttachments is a post link' do
          is_expected.to be_json_eql('post'.to_json).at_path('_links/addAttachment/method')
        end

        context 'user is not allowed to edit work packages' do
          let(:permissions) { all_permissions - [:edit_work_packages] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'addAttachment' }
            let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
          end
        end

        context 'user is not allowed to add work packages' do
          let(:permissions) { all_permissions - [:add_work_packages] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'addAttachment' }
            let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
          end
        end

        context 'user is neither allowed to edit work packages nor to add them' do
          let(:permissions) { all_permissions - [:edit_work_packages, :add_work_packages] }

          it_behaves_like 'has no link' do
            let(:link) { 'addAttachment' }
          end
        end
      end

      context 'when the user is not watching the work package' do
        it 'should have a link to watch' do
          expect(subject).to be_json_eql(
                               api_v3_paths.work_package_watchers(work_package.id).to_json)
            .at_path('_links/watch/href')
        end

        it 'should not have a link to unwatch' do
          expect(subject).not_to have_json_path('_links/unwatch/href')
        end
      end

      context 'when the user is watching the work package' do
        before do
          work_package.watcher_users << current_user
        end

        it 'should have a link to unwatch' do
          expect(subject).to be_json_eql(
                               api_v3_paths.watcher(current_user.id, work_package.id).to_json)
            .at_path('_links/unwatch/href')
        end

        it 'should not have a link to watch' do
          expect(subject).not_to have_json_path('_links/watch/href')
        end
      end

      context 'when the user has permission to add comments' do
        it 'should have a link to add comment' do
          expect(subject).to have_json_path('_links/addComment')
        end
      end

      context 'when the user does not have the permission to add comments' do
        let(:permissions) { all_permissions - [:add_work_package_notes] }

        it 'should not have a link to add comment' do
          expect(subject).not_to have_json_path('_links/addComment/href')
        end
      end

      context 'when the user has the permission to add and remove watchers' do
        it 'should have a link to add watcher' do
          expect(subject).to be_json_eql(
                               api_v3_paths.work_package_watchers(work_package.id).to_json)
            .at_path('_links/addWatcher/href')
        end

        it 'should have a link to remove watcher' do
          expect(subject).to be_json_eql(
                               api_v3_paths.watcher('{user_id}', work_package.id).to_json)
            .at_path('_links/removeWatcher/href')
        end
      end

      context 'when the user does not have the permission to add watchers' do
        let(:permissions) { all_permissions - [:add_work_package_watchers] }

        it 'should not have a link to add watcher' do
          expect(subject).not_to have_json_path('_links/addWatcher/href')
        end
      end

      context 'when the user does not have the permission to remove watchers' do
        let(:permissions) { all_permissions - [:delete_work_package_watchers] }

        it 'should not have a link to remove watcher' do
          expect(subject).not_to have_json_path('_links/removeWatcher/href')
        end
      end

      describe 'watchers link' do
        context 'when the user is allowed to see watchers' do
          it_behaves_like 'has an untitled link' do
            let(:link) { 'watchers' }
            let(:href) { api_v3_paths.work_package_watchers work_package.id }
          end

          it 'embeds the watchers as collection' do
            is_expected.to be_json_eql('Collection'.to_json).at_path('_embedded/watchers/_type')
          end
        end

        context 'when the user is not allowed to see watchers' do
          let(:permissions) { all_permissions - [:view_work_package_watchers] }

          it_behaves_like 'has no link' do
            let(:link) { 'watchers' }
          end
        end
      end

      describe 'relations' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'relations' }
          let(:href) { "/api/v3/work_packages/#{work_package.id}/relations" }
        end

        context 'when the user has the permission to manage relations' do
          it 'should have a link to add relation' do
            expect(subject).to have_json_path('_links/addRelation/href')
          end
        end

        context 'when the user does not have the permission to manage relations' do
          let(:permissions) { all_permissions - [:manage_work_package_relations] }

          it 'should not have a link to add relation' do
            expect(subject).not_to have_json_path('_links/addRelation/href')
          end
        end
      end

      context 'when the user has the permission to add work packages' do
        it 'should have a link to add child' do
          expect(subject).to be_json_eql("/api/v3/projects/#{project.identifier}/work_packages".to_json)
            .at_path('_links/addChild/href')
        end
      end

      context 'when the user does not have the permission to add work packages' do
        let(:permissions) { all_permissions - [:add_work_packages] }

        it 'should not have a link to add child' do
          expect(subject).not_to have_json_path('_links/addChild/href')
        end
      end

      context 'when the user has the permission to view time entries' do
        it 'should have a link to add child' do
          expect(subject).to have_json_path('_links/timeEntries/href')
        end
      end

      context 'when the user does not have the permission to view time entries' do
        let(:permissions) { all_permissions - [:view_time_entries] }

        it 'should not have a link to timeEntries' do
          expect(subject).not_to have_json_path('_links/timeEntries/href')
        end
      end

      describe 'linked relations' do
        let(:project) { FactoryGirl.create(:project, is_public: false) }
        let(:forbidden_project) { FactoryGirl.create(:project, is_public: false) }
        let(:user) { FactoryGirl.create(:user, member_in_project: project) }

        before do
          login_as(user)
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        describe 'parent' do
          let(:visible_parent) { FactoryGirl.create(:work_package, project: project) }
          let(:invisible_parent) { FactoryGirl.create(:work_package, project: forbidden_project) }
          let(:work_package) { FactoryGirl.create(:work_package, project: project) }

          context 'no parent' do
            it_behaves_like 'has an empty link' do
              let(:link) { 'parent' }
            end
          end

          context 'parent is visible' do
            let(:work_package) do
              FactoryGirl.create(:work_package,
                                 project: project,
                                 parent_id: visible_parent.id)
            end

            it_behaves_like 'has a titled link' do
              let(:link) { 'parent' }
              let(:href) { api_v3_paths.work_package(visible_parent.id) }
              let(:title) { visible_parent.subject }
            end

            it 'renders it as the ancestors' do
              expect(subject).to have_json_size(1).at_path('_links/ancestors')
            end
          end

          context 'parent not visible' do
            let(:work_package) do
              FactoryGirl.create(:work_package,
                                 project: project,
                                 parent_id: invisible_parent.id)
            end

            it_behaves_like 'has no link' do
              let(:link) { 'parent' }
            end

            it 'renders empty ancestors' do
              expect(subject).to have_json_size(0).at_path('_links/ancestors')
            end
          end
        end

        context 'ancestors' do
          let(:root) { FactoryGirl.build_stubbed(:work_package, project: project) }
          let(:intermediate) do
            FactoryGirl.build_stubbed(:work_package, parent: root, project: project)
          end

          context 'when ancestors are visible' do
            before do
              expect(work_package).to receive(:visible_ancestors)
                .and_return([root, intermediate])
            end

            it 'renders two items in ancestors' do
              expect(subject).to have_json_size(2).at_path('_links/ancestors')
              expect(parse_json(subject)['_links']['ancestors'][0]['title'])
                .to eq(root.subject)
              expect(parse_json(subject)['_links']['ancestors'][1]['title'])
                .to eq(intermediate.subject)
            end
          end

          context 'when ancestors are invisible' do
            before do
              expect(work_package).to receive(:visible_ancestors)
                .and_return([])
            end

            it 'renders the root node in ancestors' do
              expect(subject).to have_json_size(0).at_path('_links/ancestors')
            end
          end
        end

        context 'children' do
          let(:work_package) { FactoryGirl.create(:work_package, project: project) }
          let!(:forbidden_work_package) {
            FactoryGirl.create(:work_package,
                               project: forbidden_project,
                               parent_id: work_package.id)
          }

          it { expect(subject).not_to have_json_path('_links/children') }

          describe 'visible and invisible children' do
            let!(:child) {
              FactoryGirl.create(:work_package,
                                 project: project,
                                 parent_id: work_package.id)
            }

            it { expect(subject).to have_json_size(1).at_path('_links/children') }

            it do
              expect(parse_json(subject)['_links']['children'][0]['title']).to eq(child.subject)
            end
          end
        end
      end

      it_behaves_like 'has an untitled action link' do
        let(:link) { 'delete' }
        let(:href) { api_v3_paths.work_package(work_package.id) }
        let(:method) { :delete }
        let(:permission) { :delete_work_packages }
      end

      describe 'logTime' do
        it_behaves_like 'action link' do
          let(:action) { 'logTime' }
          let(:permission) { :log_time }
        end
      end

      describe 'move' do
        it_behaves_like 'action link' do
          let(:action) { 'move' }
          let(:permission) { :move_work_packages }
        end
      end

      describe 'copy' do
        it_behaves_like 'action link' do
          let(:action) { 'copy' }
          let(:permission) { :move_work_packages }
        end
      end

      describe 'pdf' do
        it_behaves_like 'action link' do
          let(:action) { 'pdf' }
          let(:permission) { :export_work_packages }
          let(:href) { "/work_packages/#{work_package.id}.pdf" }
        end
      end

      describe 'atom' do
        context 'with feeds enabled', with_settings: { feeds_enabled?: true } do
          it_behaves_like 'action link' do
            let(:action) { 'atom' }
            let(:permission) { :export_work_packages }
            let(:href) { "/work_packages/#{work_package.id}.atom" }
          end
        end

        context 'with feeds disabled', with_settings: { feeds_enabled?: false } do
          let(:permissions) { all_permissions + [:export_work_packages] }
          it_behaves_like 'has no link' do
            let(:link) { 'atom' }
          end
        end
      end

      describe 'changeParent' do
        it_behaves_like 'action link' do
          let(:action) { 'changeParent' }
          let(:permission) { :manage_subtasks }
        end
      end

      describe 'availableWatchers' do
        it_behaves_like 'action link' do
          let(:action) { 'availableWatchers' }
          let(:permission) { :add_work_package_watchers }
        end
      end

      describe 'customFields' do
        it_behaves_like 'action link' do
          let(:action) { 'customFields' }
          let(:permission) { :edit_project }
          let(:href) { settings_project_path(work_package.project.identifier, tab: 'custom_fields') }
        end
      end

      describe 'formConfiguration' do
        context 'when not admin' do
          it_behaves_like 'has no link' do
            let(:link) { 'formConfiguration' }
          end
        end
        context 'when admin' do
          let!(:current_user) { FactoryGirl.create :admin }

          it_behaves_like 'has a titled link' do
            let(:link) { 'configureForm' }
            let(:href) { edit_type_path(work_package.type_id, tab: 'form_configuration') }
            let(:title) { 'Configure form' }
          end
        end
      end
    end

    describe '_embedded' do
      it { is_expected.to have_json_type(Object).at_path('_embedded') }

      describe 'status' do
        let(:status) { work_package.status }

        it { is_expected.to have_json_path('_embedded/status') }

        it { is_expected.to be_json_eql('Status'.to_json).at_path('_embedded/status/_type') }

        it { is_expected.to be_json_eql(status.name.to_json).at_path('_embedded/status/name') }

        it {
          is_expected.to be_json_eql(status.is_closed.to_json).at_path('_embedded/status/isClosed')
        }
      end

      describe 'activities' do
        it 'is not embedded' do
          is_expected.not_to have_json_path('_embedded/activities')
        end
      end

      context 'not embedding links' do
        let(:embed_links) { false }

        it 'does not embed anything' do
          is_expected.not_to have_json_path('_embedded')
        end
      end

      describe 'relations' do
        let(:visible_work_package) do
          wp = FactoryGirl.build_stubbed(:work_package)

          allow(wp)
            .to receive(:visible?)
            .and_return true

          wp
        end
        let(:visible_relation) do
          relation = FactoryGirl.build_stubbed(:relation,
                                               from: work_package)

          allow(relation)
            .to receive(:other_work_package)
            .with(work_package)
            .and_return(visible_work_package)

          relation
        end
        let(:invisible_work_package) do
          wp = FactoryGirl.build_stubbed(:work_package)

          allow(wp)
            .to receive(:visible?)
            .and_return false

          wp
        end
        let(:invisible_relation) do
          relation = FactoryGirl.build_stubbed(:relation,
                                               from: work_package)

          allow(relation)
            .to receive(:other_work_package)
            .with(work_package)
            .and_return(invisible_work_package)

          relation
        end

        before do
          allow(work_package)
            .to receive(:relations)
            .and_return([visible_relation, invisible_relation])
        end

        it 'embeds a collection' do
          is_expected
            .to be_json_eql('Collection'.to_json)
            .at_path('_embedded/relations/_type')
        end

        it 'embeds with an href containing the work_package' do
          is_expected
            .to be_json_eql(api_v3_paths.work_package_relations(work_package.id).to_json)
            .at_path('_embedded/relations/_links/self/href')
        end

        it 'embeds only the visible relations' do
          is_expected
            .to be_json_eql(1.to_json)
            .at_path('_embedded/relations/total')

          is_expected
            .to be_json_eql(api_v3_paths.relation(visible_relation.id).to_json)
            .at_path('_embedded/relations/_embedded/elements/0/_links/self/href')
        end
      end
    end
  end
end
