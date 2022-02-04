#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'spec_helper'

describe Projects::CopyService, 'integration', type: :model do
  shared_let(:status_locked) { FactoryBot.create :status, is_readonly: true }
  shared_let(:source) { FactoryBot.create :project, enabled_module_names: %w[wiki work_package_tracking] }
  shared_let(:source_wp) { FactoryBot.create :work_package, project: source, subject: 'source wp' }
  shared_let(:source_wp_locked) do
    FactoryBot.create :work_package, project: source, subject: 'source wp locked', status: status_locked
  end
  shared_let(:source_query) { FactoryBot.create :query, project: source, name: 'My query' }
  shared_let(:source_category) { FactoryBot.create :category, project: source, name: 'Stock management' }
  shared_let(:source_version) { FactoryBot.create :version, project: source, name: 'Version A' }
  shared_let(:source_wiki_page) { FactoryBot.create(:wiki_page_with_content, wiki: source.wiki) }
  shared_let(:source_child_wiki_page) { FactoryBot.create(:wiki_page_with_content, wiki: source.wiki, parent: source_wiki_page) }
  shared_let(:source_forum) { FactoryBot.create(:forum, project: source) }
  shared_let(:source_topic) { FactoryBot.create(:message, forum: source_forum) }

  let(:current_user) do
    FactoryBot.create(:user,
                      member_in_project: source,
                      member_through_role: role)
  end
  let(:role) { FactoryBot.create :role, permissions: %i[copy_projects view_work_packages] }
  shared_let(:new_project_role) { FactoryBot.create :role, permissions: %i[] }
  let(:instance) do
    described_class.new(source: source, user: current_user)
  end
  let(:only_args) { nil }
  let(:target_project_params) do
    { name: 'Some name', identifier: 'some-identifier' }
  end
  let(:params) do
    { target_project_params: target_project_params, only: only_args }
  end

  before do
    with_enterprise_token(:readonly_work_packages)

    allow(Setting)
      .to receive(:new_project_user_role_id)
      .and_return(new_project_role.id.to_s)
  end

  describe 'call' do
    subject { instance.call(params) }
    let(:project_copy) { subject.result }

    context 'restricting only to members and categories' do
      let(:only_args) { %w[members categories] }

      it 'should limit copying' do
        expect(subject).to be_success

        expect(project_copy.members.count).to eq 1
        expect(project_copy.categories.count).to eq 1
        expect(project_copy.work_packages.count).to eq 0
        expect(project_copy.forums.count).to eq 0
        expect(project_copy.wiki.pages.count).to eq 0
        expect(project_copy.versions.count).to eq 0
        expect(project_copy.queries.count).to eq 0
      end
    end

    it 'will copy all dependencies and set attributes' do
      expect(subject).to be_success

      expect(project_copy.members.count).to eq 1
      expect(project_copy.categories.count).to eq 1
      # normal wp and locked wp
      expect(project_copy.work_packages.count).to eq 2
      expect(project_copy.forums.count).to eq 1
      expect(project_copy.forums.first.messages.count).to eq 1
      expect(project_copy.wiki).to be_present
      expect(project_copy.wiki.pages.count).to eq 2
      expect(project_copy.queries.count).to eq 1
      expect(project_copy.versions.count).to eq 1
      expect(project_copy.wiki.pages.root.content.text).to eq source_wiki_page.content.text
      expect(project_copy.wiki.pages.leaves.first.content.text).to eq source_child_wiki_page.content.text
      expect(project_copy.wiki.start_page).to eq 'Wiki'

      # Cleared attributes
      expect(project_copy).to be_persisted
      expect(project_copy.name).to eq 'Some name'
      expect(project_copy.name).to eq 'Some name'
      expect(project_copy.identifier).to eq 'some-identifier'

      # Duplicated attributes
      expect(project_copy.description).to eq source.description
      expect(source.enabled_module_names.sort - %w[repository]).to eq project_copy.enabled_module_names.sort
      expect(project_copy.types).to eq source.types

      # Default attributes
      expect(project_copy).to be_active

      # Default role being assigned according to setting
      #  merged with the role the user already had.
      member = project_copy.members.first
      expect(member.principal)
        .to eql(current_user)
      expect(member.roles)
        .to match_array [role, new_project_role]
    end

    it 'will copy the work package with category' do
      source_wp.update!(category: source_category)

      expect(subject).to be_success

      wp = project_copy.work_packages.find_by(subject: source_wp.subject)
      expect(wp.category.name).to eq 'Stock management'
      # Category got copied
      expect(wp.category.id).not_to eq source_category.id
    end

    describe '#public' do
      before do
        source.update!(public: public)
      end

      context 'when not public' do
        let(:public) { false }

        it 'copies correctly' do
          expect(subject).to be_success
          expect(project_copy.public).to eq public
        end
      end

      context 'when public' do
        let(:public) { true }

        it 'copies correctly' do
          expect(subject).to be_success
          expect(project_copy.public).to eq public
        end
      end
    end

    context 'with an assigned version' do
      let!(:assigned_version) { FactoryBot.create(:version, name: 'Assigned Issues', project: source, status: 'open') }

      before do
        source_wp.update!(version: assigned_version)
        assigned_version.update!(status: 'closed')
      end

      it 'will update the version' do
        expect(subject).to be_success

        wp = project_copy.work_packages.find_by(subject: source_wp.subject)
        expect(wp.version.name).to eq 'Assigned Issues'
        expect(wp.version).to be_closed
        expect(wp.version.id).not_to eq assigned_version.id
      end
    end

    context 'with group memberships' do
      let(:only_args) { %w[members] }

      let!(:user) { FactoryBot.create :user }
      let!(:another_role) { FactoryBot.create(:role) }
      let!(:group) do
        FactoryBot.create :group, members: [user]
      end

      it 'will copy them as well' do
        Members::CreateService
          .new(user: current_user, contract_class: EmptyContract)
          .call(principal: group, roles: [another_role], project: source)

        source.users.reload
        expect(source.users).to include current_user
        expect(source.users).to include user
        expect(project_copy.groups).to include group
        expect(source.member_principals.count).to eq 3

        expect(subject).to be_success

        expect(project_copy.member_principals.count).to eq 3
        expect(project_copy.groups).to include group
        expect(project_copy.users).to include current_user
        expect(project_copy.users).to include user

        group_member = Member.find_by(user_id: group.id, project_id: project_copy.id)
        expect(group_member).to be_present
        expect(group_member.roles.map(&:id)).to eq [another_role.id]

        member = Member.find_by(user_id: user.id, project_id: project_copy.id)
        expect(member).to be_present
        expect(member.roles.map(&:id)).to eq [another_role.id]
        expect(member.member_roles.first.inherited_from).to eq group_member.member_roles.first.id
      end
    end

    context 'with work package relations', with_settings: { cross_project_work_package_relations: '1' } do
      let!(:source_wp2) { FactoryBot.create(:work_package, project: source, subject: 'source wp2') }
      let!(:source_relation) { FactoryBot.create(:relation, from: source_wp, to: source_wp2, relation_type: 'relates') }

      let!(:other_project) { FactoryBot.create(:project) }
      let!(:other_wp) { FactoryBot.create(:work_package, project: other_project, subject: 'other wp') }
      let!(:cross_relation) { FactoryBot.create(:relation, from: source_wp, to: other_wp, relation_type: 'duplicates') }

      let(:only_args) { %w[work_packages] }

      it 'should the relations relations' do
        expect(subject).to be_success

        expect(source.work_packages.count).to eq(project_copy.work_packages.count)
        copied_wp = project_copy.work_packages.find_by(subject: 'source wp')
        copied_wp_2 = project_copy.work_packages.find_by(subject: 'source wp2')

        # First issue with a relation on project
        # copied relation + reflexive relation
        expect(copied_wp.relations.direct.count).to eq 2
        relates_relation = copied_wp.relations.direct.find { |r| r.relation_type == 'relates' }
        expect(relates_relation.from_id).to eq copied_wp.id
        expect(relates_relation.to_id).to eq copied_wp_2.id

        # Second issue with a cross project relation
        # copied relation + reflexive relation
        duplicates_relation = copied_wp.relations.direct.find { |r| r.relation_type == 'duplicates' }
        expect(duplicates_relation.from_id).to eq copied_wp.id
        expect(duplicates_relation.to_id).to eq other_wp.id
      end
    end

    describe '#copy_wiki' do
      it 'will not copy wiki pages without content' do
        source.wiki.pages << FactoryBot.create(:wiki_page)
        expect(source.wiki.pages.count).to eq 3

        expect(subject).to be_success
        expect(subject.errors).to be_empty
        expect(project_copy.wiki.pages.count).to eq 2
      end

      it 'will copy menu items' do
        source.wiki.wiki_menu_items << FactoryBot.create(:wiki_menu_item_with_parent, wiki: source.wiki)

        expect(subject).to be_success
        expect(project_copy.wiki.wiki_menu_items.count).to eq 3
      end
    end

    describe 'valid queries' do
      context 'with a filter' do
        let!(:query) do
          query = FactoryBot.build(:query, project: source)
          query.add_filter('subject', '~', ['bogus'])
          query.save!
        end

        it 'produces a valid query in the new project' do
          expect(subject).to be_success
          expect(project_copy.queries.all?(&:valid?)).to eq(true)
          expect(project_copy.queries.count).to eq 2
        end
      end

      context 'with a filter to be mapped' do
        let!(:query) do
          query = FactoryBot.build(:query, project: source)
          query.add_filter('parent', '=', [source_wp.id.to_s])
          # Not valid due to wp not visible
          query.save!(validate: false)
          query
        end

        it 'produces a valid query that is mapped in the new project' do
          expect(subject).to be_success
          copied_wp = project_copy.work_packages.find_by(subject: 'source wp')
          copied = project_copy.queries.find_by(name: query.name)
          expect(copied.filters[1].values).to eq [copied_wp.id.to_s]
        end
      end
    end

    describe 'query menu items' do
      let!(:query) do
        query = FactoryBot.build(:query, project: source, name: 'Query with item')
        query.add_filter('subject', '~', ['bogus'])
        query.save!

        MenuItems::QueryMenuItem.create(
          navigatable_id: query.id,
          name: 'some-uuid',
          title: 'My query title'
        )

        query
      end

      it 'copies the menu item' do
        expect(subject).to be_success
        query = project_copy.queries.find_by(name: 'Query with item')
        expect(query).to be_present
        expect(query.query_menu_item.title).to eq('My query title')
      end
    end

    describe 'work packages' do
      let(:work_package) { FactoryBot.create(:work_package, project: source) }
      let(:work_package2) { FactoryBot.create(:work_package, project: source) }
      let(:work_package3) { FactoryBot.create(:work_package, project: source) }

      let(:only_args) { %w[work_packages] }

      describe '#attachments' do
        let!(:attachment) { FactoryBot.create(:attachment, container: work_package) }

        context 'when requested' do
          let(:only_args) { %i[work_packages work_package_attachments] }
          it 'copies them' do
            expect(subject).to be_success
            expect(project_copy.work_packages.count).to eq(3)

            wp = project_copy.work_packages.find_by(subject: work_package.subject)
            expect(wp.attachments.count).to eq(1)
            expect(wp.attachments.first.author).to eql(current_user)
          end
        end

        context 'when not requested' do
          it 'ignores them' do
            expect(subject).to be_success
            expect(project_copy.work_packages.count).to eq(3)

            wp = project_copy.work_packages.find_by(subject: work_package.subject)
            expect(wp.attachments.count).to eq(0)
          end
        end
      end

      describe 'in an ordered query (Feature #31317)' do
        let!(:query) do
          FactoryBot.create(:query, name: 'Manual query', user: current_user, project: source, show_hierarchies: false).tap do |q|
            q.sort_criteria = [[:manual_sorting, 'asc']]
            q.save!
          end
        end

        before do
          ::OrderedWorkPackage.create(query: query, work_package: work_package, position: 100)
          ::OrderedWorkPackage.create(query: query, work_package: work_package2, position: 0)
          ::OrderedWorkPackage.create(query: query, work_package: work_package3, position: 50)
        end

        let(:only_args) { %w[work_packages queries] }

        it 'copies the query and order' do
          expect(subject).to be_success
          expect(project_copy.work_packages.count).to eq(5)
          expect(project_copy.queries.count).to eq(2)

          manual_query = project_copy.queries.find_by name: 'Manual query'
          expect(manual_query).to be_manually_sorted

          expect(query.ordered_work_packages.count).to eq 3
          original_order = query.ordered_work_packages.map { |ow| ow.work_package.subject }
          copied_order = manual_query.ordered_work_packages.map { |ow| ow.work_package.subject }

          expect(copied_order).to eq(original_order)
        end

        context 'if one work package is a cross project reference' do
          let(:other_project) { FactoryBot.create :project }
          before do
            work_package2.update! project: other_project
          end

          let(:only_args) { %w[work_packages queries] }

          it 'copies the query and order' do
            expect(subject).to be_success
            # Only 4 out of the 5 work packages got copied this time
            expect(project_copy.work_packages.count).to eq(4)
            expect(project_copy.queries.count).to eq(2)

            manual_query = project_copy.queries.find_by name: 'Manual query'
            expect(manual_query).to be_manually_sorted

            expect(query.ordered_work_packages.count).to eq 3
            original_order = query.ordered_work_packages.map { |ow| ow.work_package.subject }
            copied_order = manual_query.ordered_work_packages.map { |ow| ow.work_package.subject }

            expect(copied_order).to eq(original_order)

            # Expect reference to the original work package
            referenced = query.ordered_work_packages.detect { |ow| ow.work_package == work_package2 }
            expect(referenced).to be_present
          end
        end
      end

      describe '#parent' do
        before do
          work_package.parent = work_package2
          work_package.save!
          work_package2.parent = work_package3
          work_package2.save!
        end

        it do
          expect(subject).to be_success

          grandparent_wp_copy = project_copy.work_packages.find_by(subject: work_package3.subject)
          parent_wp_copy = project_copy.work_packages.find_by(subject: work_package2.subject)
          child_wp_copy = project_copy.work_packages.find_by(subject: work_package.subject)

          [grandparent_wp_copy,
           parent_wp_copy,
           child_wp_copy].each do |wp|
            expect(wp).to be_present
          end

          expect(child_wp_copy.parent).to eq(parent_wp_copy)
          expect(parent_wp_copy.parent).to eq(grandparent_wp_copy)
        end
      end

      describe '#category' do
        let(:only_args) { %w[work_packages categories] }

        before do
          wp = work_package
          wp.category = FactoryBot.create(:category, project: source)
          wp.save

          source.work_packages << wp.reload
        end

        it do
          expect(subject).to be_success
          wp = project_copy.work_packages.find_by(subject: work_package.subject)
          expect(cat = wp.category).not_to eq(nil)
          expect(cat.project).to eq(project_copy)
        end
      end

      describe '#watchers' do
        let(:watcher_role) { FactoryBot.create(:role, permissions: [:view_work_packages]) }
        let(:watcher) { FactoryBot.create(:user, member_in_project: source, member_through_role: watcher_role) }

        let(:only_args) { %w[work_packages members] }

        describe '#active_watcher' do
          before do
            wp = work_package
            wp.add_watcher watcher
            wp.save

            source.work_packages << wp
          end

          it 'does copy active watchers but does not add the copying user as a watcher' do
            expect(subject).to be_success
            expect(project_copy.work_packages[0].watcher_users)
              .to match_array([watcher])
          end
        end

        describe '#locked_watcher' do
          before do
            user = watcher
            wp = work_package
            wp.add_watcher user
            wp.save

            user.lock!

            source.work_packages << wp
          end

          it 'does not copy locked watchers and does not add the copying user as a watcher' do
            expect(subject).to be_success
            expect(project_copy.work_packages[0].watcher_users).to be_empty
          end
        end

        describe 'versions' do
          let(:version) { FactoryBot.create(:version, project: source) }
          let(:version2) { FactoryBot.create(:version, project: source) }

          let(:only_args) { %w[versions work_packages] }

          before do
            work_package.update_column(:version_id, version.id)
            work_package2.update_column(:version_id, version2.id)
            work_package3
          end

          it 'assigns the work packages to copies of the versions' do
            expect(subject).to be_success
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package.subject }.version.name)
              .to eql version.name
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package2.subject }.version.name)
              .to eql version2.name
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package3.subject }.version)
              .to be_nil
          end
        end
      end

      describe 'assigned_to' do
        before do
          work_package.update_column(:assigned_to_id, current_user.id)
        end

        context 'with the members being copied' do
          let(:only_args) { %w[members work_packages] }

          it 'copies the assigned_to' do
            expect(subject).to be_success
            expect(project_copy.users).to include current_user
            expect(project_copy.work_packages[0].assigned_to)
              .to eql current_user
          end
        end

        context 'with the assignee not being a member' do
          let(:only_args) { %w[work_packages] }

          it 'nils the assigned_to' do
            expect(subject).to be_success
            expect(project_copy.work_packages[0].assigned_to)
              .to be_nil
          end
        end
      end

      describe 'responsible' do
        before do
          work_package.update_column(:responsible_id, current_user.id)
        end

        context 'with the members being copied' do
          let(:only_args) { %w[members work_packages] }

          it 'copies the responsible' do
            expect(subject).to be_success
            expect(project_copy.users).to include current_user
            expect(project_copy.work_packages[0].responsible)
              .to eql current_user
          end
        end

        context 'with the responsible not being a member' do
          let(:only_args) { %w[work_packages] }

          it 'nils the assigned_to' do
            expect(subject).to be_success
            expect(project_copy.work_packages[0].responsible)
              .to be_nil
          end
        end
      end

      describe 'work package user custom field' do
        let(:custom_field) do
          FactoryBot.create(:user_wp_custom_field).tap do |cf|
            source.work_package_custom_fields << cf
            work_package.type.custom_fields << cf
          end
        end

        before do
          custom_field
          work_package.reload
          work_package.send(:"custom_field_#{custom_field.id}=", current_user.id)
          work_package.save!(validate: false)
        end

        context 'with the value being a member' do
          let(:only_args) { %w[members work_packages] }

          it 'copies the custom_field' do
            expect(subject).to be_success
            wp = project_copy.work_packages.find_by(subject: work_package.subject)
            expect(wp.send(:"custom_field_#{custom_field.id}"))
              .to eql current_user
          end
        end

        context 'with the value not being a member' do
          let(:only_args) { %w[work_packages] }

          it 'nils the custom_field' do
            expect(subject).to be_success
            wp = project_copy.work_packages.find_by(subject: work_package.subject)
            expect(wp.send(:"custom_field_#{custom_field.id}"))
              .to be_nil
          end
        end
      end
    end

    describe 'project custom fields' do
      context 'with user project CF' do
        let(:user_custom_field) { FactoryBot.create(:user_project_custom_field) }
        let(:user_value) do
          FactoryBot.create(:user,
                            member_in_project: source,
                            member_through_role: role)
        end

        before do
          source.custom_values << CustomValue.new(custom_field: user_custom_field, value: user_value.id.to_s)
        end

        let(:only_args) { %w[wiki] }

        it 'copies the custom_field' do
          expect(subject).to be_success

          cv = project_copy.custom_values.reload.find_by(custom_field: user_custom_field)
          expect(cv).to be_present
          expect(cv.value).to eq user_value.id.to_s
          expect(cv.typed_value).to eq user_value
        end
      end

      context 'with multi selection project list CF' do
        let(:list_custom_field) { FactoryBot.create(:list_project_custom_field, multi_value: true) }

        before do
          source.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of('A'))
          source.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of('B'))

          source.save!
        end

        let(:only_args) { %w[wiki] }

        it 'copies the custom_field' do
          expect(subject).to be_success

          cv = project_copy.custom_values.reload.where(custom_field: list_custom_field).to_a
          expect(cv).to be_kind_of Array
          expect(cv.count).to eq 2
          expect(cv.map(&:formatted_value)).to contain_exactly('A', 'B')
        end
      end
    end
  end
end
