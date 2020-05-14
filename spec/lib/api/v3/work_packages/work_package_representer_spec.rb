#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:member) { FactoryBot.build_stubbed(:user) }
  let(:current_user) { member }
  let(:embed_links) { true }
  let(:representer) do
    described_class.create(work_package, current_user: current_user, embed_links: embed_links)
  end
  let(:parent) { nil }
  let(:priority) { FactoryBot.build_stubbed(:priority, updated_at: Time.now) }
  let(:assignee) { nil }
  let(:responsible) { nil }
  let(:schedule_manually) { nil }
  let(:start_date) { Date.today.to_datetime }
  let(:due_date) { Date.today.to_datetime }
  let(:type_milestone) { false }
  let(:estimated_hours) { nil }
  let(:derived_estimated_hours) { nil }
  let(:spent_hours) { 0 }
  let(:work_package) do
    FactoryBot.build_stubbed(:stubbed_work_package,
                             schedule_manually: schedule_manually,
                             start_date: start_date,
                             due_date: due_date,
                             done_ratio: 50,
                             parent: parent,
                             type: type,
                             project: project,
                             priority: priority,
                             assigned_to: assignee,
                             responsible: responsible,
                             estimated_hours: estimated_hours,
                             derived_estimated_hours: derived_estimated_hours,
                             status: status) do |wp|
      allow(wp)
        .to receive(:available_custom_fields)
        .and_return(available_custom_fields)

      allow(wp)
        .to receive(:spent_hours)
        .and_return(spent_hours)
    end
  end
  let(:all_permissions) do
    %i[
      view_work_packages
      view_work_package_watchers
      edit_work_packages
      add_work_package_watchers
      delete_work_package_watchers
      manage_work_package_relations
      add_work_package_notes
      add_work_packages
      view_time_entries
      view_changesets
      delete_work_packages
    ]
  end
  let(:permissions) { all_permissions }
  let(:project) { FactoryBot.build_stubbed(:project_with_types) }
  let(:type) do
    type = project.types.first

    type.is_milestone = type_milestone

    type
  end
  let(:status) { FactoryBot.build_stubbed(:status, updated_at: Time.now) }
  let(:available_custom_fields) { [] }

  before(:each) do
    login_as current_user

    allow(current_user)
      .to receive(:allowed_to?) do |permission, _context|
      permissions.include?(permission)
    end
  end

  include_context 'eager loaded work package representer'

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('WorkPackage'.to_json).at_path('_type') }

    describe 'work_package' do
      it { is_expected.to have_json_path('id') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'markdown' }
        let(:raw) { work_package.description }
        let(:html) { '<p>' + work_package.description + '</p>' }
      end

      describe 'scheduleManually' do
        context 'no value' do
          it 'renders as false (default value)' do
            is_expected.to be_json_eql(false.to_json).at_path('scheduleManually')
          end
        end

        context 'false' do
          let(:schedule_manually) { false }

          it 'renders as false' do
            is_expected.to be_json_eql(false.to_json).at_path('scheduleManually')
          end
        end

        context 'true' do
          let(:schedule_manually) { true }

          it 'renders as true' do
            is_expected.to be_json_eql(true.to_json).at_path('scheduleManually')
          end
        end
      end

      describe 'startDate' do
        it_behaves_like 'has ISO 8601 date only' do
          let(:date) { start_date }
          let(:json_path) { 'startDate' }
        end

        context 'no start date' do
          let(:start_date) { nil }

          it 'renders as null' do
            is_expected.to be_json_eql(nil.to_json).at_path('startDate')
          end
        end

        context 'when the work package has a milestone type' do
          let(:type_milestone) { true }

          it 'has no startDate' do
            is_expected.to_not have_json_path('startDate')
          end
        end
      end

      describe 'dueDate' do
        context 'with a non milestone type' do
          it_behaves_like 'has ISO 8601 date only' do
            let(:date) { work_package.due_date }
            let(:json_path) { 'dueDate' }
          end

          context 'no finish date' do
            let(:due_date) { nil }

            it 'renders as null' do
              is_expected.to be_json_eql(nil.to_json).at_path('dueDate')
            end
          end
        end

        context 'with a milestone type' do
          let(:type_milestone) { true }

          it 'has no startDate' do
            is_expected.to_not have_json_path('dueDate')
          end
        end
      end

      describe 'date' do
        context 'with a milestone type' do
          let(:type_milestone) { true }

          it_behaves_like 'has ISO 8601 date only' do
            let(:date) { due_date } # could just as well be start_date
            let(:json_path) { 'date' }
          end

          context 'no finish date' do
            let(:due_date) { nil }

            it 'renders as null' do
              is_expected.to be_json_eql(nil.to_json).at_path('date')
            end
          end
        end

        context 'with a milestone type' do
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
      let(:estimated_hours) { 6.5 }

      it { is_expected.to be_json_eql('PT6H30M'.to_json).at_path('estimatedTime') }
    end

    describe 'derivedEstimatedTime' do
      let(:derived_estimated_hours) { 3.75 }

      it { is_expected.to be_json_eql('PT3H45M'.to_json).at_path('derivedEstimatedTime') }
    end

    describe 'spentTime' do
      # spentTime is completely overwritten by costs
      # TODO: move specs from costs to here
    end

    describe 'percentageDone' do
      describe 'work package done ratio setting behavior' do
        context 'setting enabled' do
          it { expect(parse_json(subject)['percentageDone']).to eq(50) }
        end

        context 'setting disabled' do
          before do
            allow(Setting)
              .to receive(:work_package_done_ratio)
              .and_return('disabled')
          end

          it { is_expected.to_not have_json_path('percentageDone') }
        end
      end
    end

    describe 'custom fields' do
      let(:available_custom_fields) { [FactoryBot.build_stubbed(:int_wp_custom_field)] }
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

        context 'user is lacks edit permission but has assign_versions' do
          let(:permissions) { all_permissions - [:edit_work_packages] + [:assign_versions] }

          it_behaves_like 'has an untitled link' do
            let(:link) { 'update' }
            let(:href) { api_v3_paths.work_package_form(work_package.id) }
          end

          it_behaves_like 'has an untitled link' do
            let(:link) { 'updateImmediately' }
            let(:href) { api_v3_paths.work_package(work_package.id) }
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
        context 'is user' do
          let(:assignee) { FactoryBot.build_stubbed(:user) }

          it_behaves_like 'has a titled link' do
            let(:link) { 'assignee' }
            let(:href) { "/api/v3/users/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context 'is group' do
          let(:assignee) { FactoryBot.build_stubbed(:group) }

          it_behaves_like 'has a titled link' do
            let(:link) { 'assignee' }
            let(:href) { "/api/v3/groups/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context 'is not set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'assignee' }
          end
        end
      end

      describe 'responsible' do
        context 'is user' do
          let(:responsible) { FactoryBot.build_stubbed(:user) }

          it_behaves_like 'has a titled link' do
            let(:link) { 'responsible' }
            let(:href) { "/api/v3/users/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context 'is group' do
          let(:responsible) { FactoryBot.build_stubbed(:group) }

          it_behaves_like 'has a titled link' do
            let(:link) { 'responsible' }
            let(:href) { "/api/v3/groups/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context 'is not set' do
          it_behaves_like 'has an empty link' do
            let(:link) { 'responsible' }
          end
        end
      end

      describe 'revisions' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'revisions' }
          let(:href) do
            api_v3_paths.work_package_revisions(work_package.id)
          end
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
          let!(:version) { FactoryBot.create :version, project: project }

          before do
            work_package.version = version
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
          let!(:category) { FactoryBot.build_stubbed :category }

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
          let(:href) do
            api_v3_paths.work_package_schema(work_package.project.id, work_package.type.id)
          end
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

        context 'when work package blocked' do
          before do
            allow(work_package).to receive(:readonly_status?).and_return true
          end

          it_behaves_like 'has no link' do
            let(:link) { 'addAttachment' }
          end
        end

        it 'addAttachments is a post link' do
          is_expected.to be_json_eql('post'.to_json).at_path('_links/addAttachment/method')
        end

        context 'user is not allowed to edit work packages' do
          let(:permissions) { all_permissions - %i[edit_work_packages] }

          it_behaves_like 'has no link' do
            let(:link) { 'addAttachment' }
          end
        end
      end

      context 'when the user is not watching the work package' do
        it 'should have a link to watch' do
          expect(subject)
            .to be_json_eql(api_v3_paths.work_package_watchers(work_package.id).to_json)
            .at_path('_links/watch/href')
        end

        it 'should not have a link to unwatch' do
          expect(subject).not_to have_json_path('_links/unwatch/href')
        end
      end

      context 'when the user is watching the work package' do
        let(:watchers) { [FactoryBot.build_stubbed(:watcher, watchable: work_package, user: current_user)] }

        before do
          allow(work_package)
            .to receive(:watchers)
            .and_return(watchers)
        end

        it 'should have a link to unwatch' do
          expect(subject)
            .to be_json_eql(api_v3_paths.watcher(current_user.id, work_package.id).to_json)
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
        let(:project) { FactoryBot.create(:project, public: false) }
        let(:forbidden_project) { FactoryBot.create(:project, public: false) }
        let(:user) { FactoryBot.create(:user, member_in_project: project) }

        before do
          login_as(user)
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        describe 'parent' do
          let(:visible_parent) do
            FactoryBot.build_stubbed(:stubbed_work_package) do |wp|
              allow(wp)
                .to receive(:visible?)
                .and_return(true)
            end
          end
          let(:invisible_parent) do
            FactoryBot.build_stubbed(:stubbed_work_package) do |wp|
              allow(wp)
                .to receive(:visible?)
                      .and_return(false)
            end
          end

          context 'no parent' do
            it_behaves_like 'has an empty link' do
              let(:link) { 'parent' }
            end
          end

          context 'parent is visible' do
            let(:parent) { visible_parent }

            it_behaves_like 'has a titled link' do
              let(:link) { 'parent' }
              let(:href) { api_v3_paths.work_package(visible_parent.id) }
              let(:title) { visible_parent.subject }
            end
          end

          context 'parent not visible' do
            let(:parent) { invisible_parent }

            it_behaves_like 'has an empty link' do
              let(:link) { 'parent' }
            end
          end
        end

        context 'ancestors' do
          let(:root) { FactoryBot.build_stubbed(:work_package, project: project) }
          let(:intermediate) do
            FactoryBot.build_stubbed(:work_package, parent: root, project: project)
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

            it 'renders empty ancestors' do
              expect(subject).to have_json_size(0).at_path('_links/ancestors')
            end
          end
        end

        context 'children' do
          let(:work_package) { FactoryBot.create(:work_package, project: project) }
          let!(:forbidden_work_package) do
            FactoryBot.create(:work_package,
                              project: forbidden_project,
                              parent: work_package)
          end

          it { expect(subject).not_to have_json_path('_links/children') }

          describe 'visible and invisible children' do
            let!(:child) do
              FactoryBot.create(:work_package,
                                project: project,
                                parent: work_package)
            end

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
        it_behaves_like 'has a titled action link' do
          let(:link) { 'copy' }
          let(:href) { work_package_path(work_package, 'copy') }
          let(:permission) { :add_work_packages }
          let(:title) { "Copy #{work_package.subject}" }
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
          let(:href) { settings_custom_fields_project_path(work_package.project.identifier) }
        end
      end

      describe 'formConfiguration' do
        context 'when not admin' do
          it_behaves_like 'has no link' do
            let(:link) { 'formConfiguration' }
          end
        end
        context 'when admin' do
          let(:current_user) { FactoryBot.build_stubbed :admin }

          it_behaves_like 'has a titled link' do
            let(:link) { 'configureForm' }
            let(:href) { edit_type_path(work_package.type_id, tab: 'form_configuration') }
            let(:title) { 'Configure form' }
          end
        end
      end

      describe 'customActions' do
        it 'has a collection of customActions' do
          unassign_action = FactoryBot.build_stubbed(:custom_action,
                                                     actions: [CustomActions::Actions::AssignedTo.new(value: nil)],
                                                     name: 'Unassign')
          allow(work_package)
            .to receive(:custom_actions)
            .and_return([unassign_action])

          expected = [
            {
              href: api_v3_paths.custom_action(unassign_action.id),
              title: unassign_action.name
            }
          ]

          is_expected
            .to be_json_eql(expected.to_json)
            .at_path('_links/customActions')
        end
      end
    end

    describe '_embedded' do
      it { is_expected.to have_json_type(Object).at_path('_embedded') }

      describe 'status' do
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

      describe 'relations' do
        let(:relation) do
          FactoryBot.build_stubbed(:relation,
                                   from: work_package)
        end

        before do
          allow(work_package)
            .to receive_message_chain(:visible_relations, :non_hierarchy, :includes)
            .and_return([relation])
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

        it 'embeds the visible relations' do
          is_expected
            .to be_json_eql(1.to_json)
            .at_path('_embedded/relations/total')

          is_expected
            .to be_json_eql(api_v3_paths.relation(relation.id).to_json)
            .at_path('_embedded/relations/_embedded/elements/0/_links/self/href')
        end
      end

      describe 'customActions' do
        it 'has an array of customActions' do
          unassign_action = FactoryBot.build_stubbed(:custom_action,
                                                     actions: [CustomActions::Actions::AssignedTo.new(value: nil)],
                                                     name: 'Unassign')
          allow(work_package)
            .to receive(:custom_actions)
            .and_return([unassign_action])

          is_expected
            .to be_json_eql('Unassign'.to_json)
            .at_path('_embedded/customActions/0/name')
        end
      end
    end

    describe 'caching' do
      it 'is based on the representer\'s cache_key' do
        allow(OpenProject::Cache)
          .to receive(:fetch)
          .and_return({_links: {}}.to_json)
        expect(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json
      end

      describe '#json_cache_key' do
        let(:category) { FactoryBot.build_stubbed(:category) }
        let(:assigned_to) { FactoryBot.build_stubbed(:user) }
        let(:responsible) { FactoryBot.build_stubbed(:user) }

        before do
          work_package.category = category
          work_package.assigned_to = assigned_to
          work_package.responsible = responsible
        end
        let!(:former_cache_key) { representer.json_cache_key }

        it 'includes the name of the representer class' do
          expect(representer.json_cache_key)
            .to include('API', 'V3', 'WorkPackages', 'WorkPackageRepresenter')
        end

        it 'changes when the locale changes' do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it 'changes when the feeds_enabled? setting is switched' do
          allow(Setting)
            .to receive(:feeds_enabled?)
            .and_return(!Setting.feeds_enabled?)

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the work_package_done_ratio setting is changes' do
          allow(Setting)
            .to receive(:work_package_done_ratio)
            .and_return('status')

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the work_package is updated' do
          work_package.updated_at = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'factors in the eager loaded cache_checksum' do
          expect(work_package)
            .to receive(:cache_checksum)
            .and_return(srand)

          representer.json_cache_key
        end
      end
    end
  end
end
