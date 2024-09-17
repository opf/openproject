# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe(
  Projects::CopyService,
  "integration",
  :webmock,
  type: :model,
  with_ee: %i[readonly_work_packages]
) do
  shared_let(:status_locked) { create(:status, is_readonly: true) }
  shared_let(:source) do
    create(:project,
           name: "Source Project Name",
           enabled_module_names: %i[wiki work_package_tracking storages])
  end
  shared_let(:source_wp) { create(:work_package, project: source, subject: "source wp") }
  shared_let(:source_wp_locked) do
    create(:work_package, project: source, subject: "source wp locked", status: status_locked)
  end
  shared_let(:source_query) { create(:query, project: source, name: "My query") }
  shared_let(:source_view) { create(:view_work_packages_table, query: source_query) }
  shared_let(:source_category) { create(:category, project: source, name: "Stock management") }
  shared_let(:source_version) { create(:version, project: source, name: "Version A") }
  shared_let(:source_wiki_page) { create(:wiki_page, wiki: source.wiki) }
  shared_let(:source_child_wiki_page) { create(:wiki_page, wiki: source.wiki, parent: source_wiki_page) }
  shared_let(:source_forum) { create(:forum, project: source) }
  shared_let(:source_topic) { create(:message, forum: source_forum) }

  let(:current_user) do
    create(:user,
           member_with_roles: { source => role })
  end
  let(:instance) { described_class.new(source:, user: current_user) }
  let(:only_args) { nil }
  let(:target_project_params) do
    { name: "Target Project Name", identifier: "some-identifier" }
  end
  let(:params) do
    { target_project_params:, only: only_args, send_notifications: }
  end
  let(:send_notifications) { true }

  shared_let(:role) do
    create(:project_role,
           permissions: %i[copy_projects
                           view_work_packages
                           work_package_assigned
                           manage_files_in_project
                           manage_file_links
                           view_project_attributes
                           edit_project_attributes])
  end
  shared_let(:new_project_role) { create(:project_role, permissions: %i[]) }

  before do
    allow(Setting)
      .to receive(:new_project_user_role_id)
            .and_return(new_project_role.id.to_s)
  end

  describe ".copyable_dependencies" do
    it "includes the list of dependencies" do
      expect(described_class.copyable_dependencies.pluck(:identifier)).to eq(
        %w(
          members
          versions
          categories
          work_packages
          work_package_attachments
          work_package_shares
          wiki
          wiki_page_attachments
          forums
          queries
          boards
          overview
          storages
          storage_project_folders
          file_links
        )
      )
    end
  end

  describe ".call" do
    subject { instance.call(params) }

    let(:all_modules) { described_class.copyable_dependencies.pluck(:identifier) }
    let(:project_copy) { subject.result }

    shared_examples_for "copies public attribute" do
      describe "#public" do
        before do
          source.update!(public:)
        end

        context "when not public" do
          let(:public) { false }

          it "copies correctly" do
            expect(subject).to be_success
            expect(project_copy.public).to eq public
          end
        end

        context "when public" do
          let(:public) { true }

          it "copies correctly" do
            expect(subject).to be_success
            expect(project_copy.public).to eq public
          end
        end
      end
    end

    shared_examples_for "copies custom fields" do
      describe "project custom fields" do
        context "with user project CF" do
          let(:user_custom_field) { create(:user_project_custom_field) }
          let(:user_value) do
            create(:user,
                   member_with_roles: { source => role })
          end

          before do
            source.custom_values << CustomValue.new(custom_field: user_custom_field, value: user_value.id.to_s)
          end

          it "copies the custom_field" do
            expect(subject).to be_success

            expect(project_copy.project_custom_fields).to contain_exactly(user_custom_field)

            cv = project_copy.custom_values.reload.find_by(custom_field: user_custom_field)
            expect(cv).to be_present
            expect(cv.value).to eq user_value.id.to_s
            expect(cv.typed_value).to eq user_value
          end
        end

        context "with multi selection project list CF" do
          let(:list_custom_field) { create(:list_project_custom_field, multi_value: true) }

          before do
            source.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of("A"))
            source.custom_values << CustomValue.new(custom_field: list_custom_field, value: list_custom_field.value_of("B"))

            source.save!
          end

          it "copies the custom_field" do
            expect(subject).to be_success

            expect(project_copy.project_custom_fields).to contain_exactly(list_custom_field)

            cv = project_copy.custom_values.reload.where(custom_field: list_custom_field).to_a
            expect(cv).to be_a Array
            expect(cv.count).to eq 2
            expect(cv.map(&:formatted_value)).to contain_exactly("A", "B")
          end
        end

        context "with disabled project custom fields with default value" do
          it "is still disabled in the copy" do
            create(:text_project_custom_field, default_value: "default value")

            expect(subject).to be_success

            expect(source.project_custom_fields).to eq([])
            expect(project_copy.project_custom_fields).to match_array(source.project_custom_fields)
          end
        end

        context "with disabled work package custom field" do
          it "is still disabled in the copy" do
            custom_field = create(:text_wp_custom_field)
            create(:type_task,
                   projects: [source],
                   custom_fields: [custom_field])

            expect(subject).to be_success

            expect(source.work_package_custom_fields).to eq([])
            expect(project_copy.work_package_custom_fields).to match_array(source.work_package_custom_fields)
          end
        end

        context "with enabled work package custom field" do
          it "is still enabled in the copy" do
            custom_field = create(:text_wp_custom_field, projects: [source])
            create(:type_task,
                   projects: [source],
                   custom_fields: [custom_field])

            expect(subject).to be_success

            expect(source.work_package_custom_fields).to eq([custom_field])
            expect(project_copy.work_package_custom_fields).to match_array(source.work_package_custom_fields)
          end
        end
      end
    end

    context "with all modules selected" do
      let(:only_args) { all_modules }
      let(:storage1) { source_automatic_project_storage.storage }
      let(:storage2) { source_manual_project_storage.storage }
      # rubocop:enable RSpec/IndexedLet

      shared_let(:source_automatic_project_storage) do
        storage = create(:nextcloud_storage)
        create(:project_storage, storage:, project: source, project_folder_id: "123", project_folder_mode: "automatic")
      end

      shared_let(:source_manual_project_storage) do
        storage = create(:nextcloud_storage)
        create(:project_storage, storage:, project: source, project_folder_id: "345", project_folder_mode: "manual")
      end

      # rubocop:disable RSpec/ExampleLength
      # rubocop:disable RSpec/MultipleExpectations
      it "copies all dependencies and set attributes" do
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
        expect(project_copy.queries[0].views.count).to eq 1
        expect(project_copy.versions.count).to eq 1
        expect(project_copy.wiki.pages.root.text).to eq source_wiki_page.text
        expect(project_copy.wiki.pages.leaves.first.text).to eq source_child_wiki_page.text
        expect(project_copy.wiki.start_page).to eq "Wiki"

        # Cleared attributes
        expect(project_copy).to be_persisted
        expect(project_copy.name).to eq "Target Project Name"
        expect(project_copy.identifier).to eq "some-identifier"

        # Duplicated attributes
        expect(project_copy.description).to eq source.description
        expect(source.enabled_module_names.sort - %w[repository]).to eq project_copy.enabled_module_names.sort
        expect(project_copy.types).to eq source.types

        # Default attributes
        expect(project_copy).to be_active

        # Default role being assigned according to setting
        #  merged with the role the user already had.
        member = project_copy.members.last
        expect(member.principal).to eql(current_user)
        expect(member.roles.reload).to contain_exactly(role, new_project_role)

        expect(project_copy.project_storages.count).to eq(2)
        automatic_project_storage_copy = project_copy.project_storages.find_by(storage: storage1)
        expect(automatic_project_storage_copy.id).not_to eq(source_automatic_project_storage.id)
        expect(automatic_project_storage_copy.project_id).to eq(project_copy.id)
        expect(automatic_project_storage_copy.creator_id).to eq(current_user.id)
        expect(automatic_project_storage_copy.project_folder_id).to be_nil
        expect(automatic_project_storage_copy.project_folder_mode).to eq("inactive")

        manual_project_storage_copy = project_copy.project_storages.find_by(storage: storage2)
        expect(manual_project_storage_copy.id).not_to eq(source_manual_project_storage.id)
        expect(manual_project_storage_copy.project_id).to eq(project_copy.id)
        expect(manual_project_storage_copy.creator_id).to eq(current_user.id)
        expect(manual_project_storage_copy.project_folder_id).to be_nil
        expect(manual_project_storage_copy.project_folder_mode).to eq("inactive")
      end
      # rubocop:enable RSpec/ExampleLength
      # rubocop:enable RSpec/MultipleExpectations

      it_behaves_like "copies public attribute"
      it_behaves_like "copies custom fields"
    end

    context "with some modules selected" do
      context "with queries" do
        let(:only_args) { %i[queries] }

        context "with a filter" do
          let!(:query) do
            build(:query, project: source).tap do |q|
              q.add_filter("subject", "~", ["bogus"])
              q.save!

              create(:view_work_packages_table, query: q)
            end
          end

          it "produces a valid query in the new project" do
            expect(subject).to be_success
            expect(project_copy.queries.all?(&:valid?)).to be(true)
            expect(project_copy.queries.count).to eq 2
          end
        end

        context "with a filter to be mapped" do
          let(:only_args) { %w(members work_packages queries) }
          let!(:query) do
            build(:query, project: source).tap do |q|
              q.add_filter("parent", "=", [source_wp.id.to_s])
              # Not valid due to wp not visible
              q.save!(validate: false)

              create(:view_work_packages_table, query: q)
            end
          end

          it "produces a valid query that is mapped in the new project" do
            expect(subject).to be_success
            copied_wp = project_copy.work_packages.find_by(subject: "source wp")
            copied = project_copy.queries.find_by(name: query.name)
            expect(copied.filters[1].values).to eq [copied_wp.id.to_s]
          end
        end

        context "with query with views" do
          let!(:query_with_view) do
            query = build(:query, project: source, name: "Query with view")
            query.add_filter("subject", "~", ["bogus"])
            query.save!

            create(:view_work_packages_table, query:)

            query
          end

          let!(:query_without_view) do
            query = build(:query, project: source, name: "Query without view")
            query.add_filter("subject", "~", ["bogus"])
            query.save!

            query
          end

          it "copies only the query with a view (non viewed queries will have to implement specific copy service)" do
            expect(subject).to be_success
            copied_query_with_view = project_copy.queries.find_by(name: "Query with view")
            expect(copied_query_with_view).to be_present
            expect(copied_query_with_view.views.length).to eq 1
            expect(copied_query_with_view.views[0].type).to eq "work_packages_table"

            expect(project_copy.queries).not_to exist(name: "Query without view")
          end
        end
      end

      context "with memeber" do
        let(:only_args) { %w[members] }

        let!(:user) { create(:user) }
        let!(:another_role) { create(:project_role) }
        let!(:group) { create(:group, members: [user]) }

        it "copies them as well" do
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

      context "with work_packages" do
        let(:only_args) { %w[work_packages] }

        let(:work_package) { create(:work_package, project: source) }

        # rubocop:disable RSpec/IndexedLet
        let(:work_package2) { create(:work_package, project: source) }
        let(:work_package3) { create(:work_package, project: source) }
        # rubocop:enable RSpec/IndexedLet

        it "does not copy work package budgets" do
          budget = create(:budget, project: source)
          source_wp.update!(budget:)

          expect(subject).to be_success

          expect(source.work_packages.count).to eq(project_copy.work_packages.count)
          copied_wp = project_copy.work_packages.find_by(subject: "source wp")
          expect(copied_wp.budget).to be_nil
        end

        context "if categories are copied" do
          let(:only_args) { %i[work_packages categories] }

          it "copies the work package with category" do
            source_wp.update!(category: source_category)

            expect(subject).to be_success

            wp = project_copy.work_packages.find_by(subject: source_wp.subject)
            expect(wp.category.name).to eq "Stock management"
            # Category got copied
            expect(wp.category.id).not_to eq source_category.id
          end
        end

        context "with an assigned version" do
          let(:only_args) { %i[work_packages versions] }
          let!(:assigned_version) { create(:version, name: "Assigned Issues", project: source, status: "open") }

          before do
            source_wp.update!(version: assigned_version)
            assigned_version.update!(status: "closed")
          end

          it "updates the version" do
            expect(subject).to be_success

            wp = project_copy.work_packages.find_by(subject: source_wp.subject)
            expect(wp.version.name).to eq "Assigned Issues"
            expect(wp.version).to be_closed
            expect(wp.version.id).not_to eq assigned_version.id
          end
        end

        context "with attachments" do
          before do
            create(:attachment, container: work_package)
            expect(work_package.attachments.count).to eq(1) # rubocop:disable RSpec/ExpectInHook
          end

          context "when requested" do
            let(:only_args) { %i[work_packages work_package_attachments] }

            it "copies them" do
              expect(subject).to be_success
              expect(project_copy.work_packages.count).to eq(3)

              wp = project_copy.work_packages.find_by(subject: work_package.subject)
              expect(wp.attachments.count).to eq(1)
              expect(wp.attachments.first.author).to eql(current_user)
            end
          end

          context "when not requested" do
            it "ignores them" do
              expect(subject).to be_success
              expect(project_copy.work_packages.count).to eq(3)

              wp = project_copy.work_packages.find_by(subject: work_package.subject)
              expect(wp.attachments.count).to eq(0)
            end
          end
        end

        context "with an ordered query (Feature #31317)" do
          let!(:query) do
            create(:query, name: "Manual query", user: current_user, project: source, show_hierarchies: false).tap do |q|
              q.sort_criteria = [[:manual_sorting, "asc"]]
              q.save!

              create(:view_work_packages_table, query: q)
            end
          end
          let(:only_args) { %w[work_packages queries] }

          before do
            OrderedWorkPackage.create(query:, work_package:, position: 100)
            OrderedWorkPackage.create(query:, work_package: work_package2, position: 0)
            OrderedWorkPackage.create(query:, work_package: work_package3, position: 50)
          end

          it "copies the query and order" do
            expect(subject).to be_success
            expect(project_copy.work_packages.count).to eq(5)
            expect(project_copy.queries.count).to eq(2)

            manual_query = project_copy.queries.find_by name: "Manual query"
            expect(manual_query).to be_manually_sorted

            expect(query.ordered_work_packages.count).to eq 3
            original_order = query.ordered_work_packages.map { |ow| ow.work_package.subject }
            copied_order = manual_query.ordered_work_packages.map { |ow| ow.work_package.subject }

            expect(copied_order).to eq(original_order)
          end

          context "if one work package is a cross project reference" do
            let(:other_project) { create(:project) }
            let(:only_args) { %w[work_packages queries] }

            before do
              work_package2.update! project: other_project
            end

            it "copies the query and order" do
              expect(subject).to be_success
              # Only 4 out of the 5 work packages got copied this time
              expect(project_copy.work_packages.count).to eq(4)
              expect(project_copy.queries.count).to eq(2)

              manual_query = project_copy.queries.find_by name: "Manual query"
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

        context "with parent work_package" do
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

            expect([grandparent_wp_copy, parent_wp_copy, child_wp_copy]).to all be_present
            expect(child_wp_copy.parent).to eq(parent_wp_copy)
            expect(parent_wp_copy.parent).to eq(grandparent_wp_copy)
          end
        end

        context "with category" do
          let(:only_args) { %w[work_packages categories] }

          before do
            wp = work_package
            wp.category = create(:category, project: source)
            wp.save

            source.work_packages << wp
          end

          it do
            expect(subject).to be_success
            wp = project_copy.work_packages.find_by(subject: work_package.subject)
            expect(cat = wp.category).not_to be_nil
            expect(cat.project).to eq(project_copy)
          end
        end

        context "with watchers" do
          let(:watcher) { create(:user, member_with_permissions: { source => [:view_work_packages] }) }

          let(:only_args) { %w[work_packages members] }

          context "with active watcher" do
            before do
              wp = work_package
              wp.add_watcher watcher
              wp.save

              source.work_packages << wp
            end

            it "does copy active watchers but does not add the copying user as a watcher" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].watcher_users)
                .to contain_exactly(watcher)
            end
          end

          context "with locked watcher" do
            before do
              user = watcher
              wp = work_package
              wp.add_watcher user
              wp.save

              user.locked!

              source.work_packages << wp
            end

            it "does not copy locked watchers and does not add the copying user as a watcher" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].watcher_users).to be_empty
            end
          end
        end

        context "with shared work packages" do
          let(:wp_role) { create(:view_work_package_role) }
          let!(:source_wp_shared_with_user) do
            create(:user, member_with_roles: { source_wp => wp_role })
          end

          let(:only_args) { %w[work_packages work_package_shares] }

          shared_examples "does not sends share notification" do
            it "does not create any notifications" do
              subject
              # The sharee is not notified
              expect { perform_enqueued_jobs }
                .not_to change(Notification.where(recipient: source_wp_shared_with_user), :count)
            end
          end

          shared_examples "sends share notification" do
            it "creates a notification for the sharee" do
              subject
              # The sharee of the new work package receives a notification
              expect { perform_enqueued_jobs }
                .to change(Notification.where(recipient: source_wp_shared_with_user), :count)
                      .from(0)
                      .to(1)
            end
          end

          shared_examples "copies the shared with membership for the work package" do
            it "copies the shared with membership for the work package" do
              expect(subject).to be_success
              expect(project_copy.members.count).to eq 2

              shared_wp_member = project_copy.members.find_by(entity_type: "WorkPackage")
              expect(shared_wp_member.principal).to eq(source_wp_shared_with_user)
              expect(shared_wp_member.roles).to contain_exactly(wp_role)

              copied_wp = project_copy.work_packages.find_by(subject: "source wp")
              expect(shared_wp_member.entity).to eq(copied_wp)
            end
          end

          it_behaves_like "copies the shared with membership for the work package"
          it_behaves_like "sends share notification"

          context "when send_notifications are disabled" do
            let(:send_notifications) { false }

            it_behaves_like "copies the shared with membership for the work package"
            it_behaves_like "does not sends share notification"
          end

          context "having disabled" do
            let(:only_args) { %w[work_packages] }

            it "copies the standard membership for the project only" do
              expect(subject).to be_success
              expect(project_copy.members.count).to eq 1

              wp_member = project_copy.members.find_by(user_id: current_user.id)
              expect(wp_member.principal).to eq(current_user)
              expect(wp_member).to be_project_role
            end

            it_behaves_like "does not sends share notification"
          end
        end

        context "with versions" do
          let(:version) { create(:version, project: source) }
          let(:version2) { create(:version, project: source) }

          let(:only_args) { %w[versions work_packages] }

          before do
            work_package.update_column(:version_id, version.id)
            work_package2.update_column(:version_id, version2.id)
            work_package3
          end

          it "assigns the work packages to copies of the versions" do
            expect(subject).to be_success
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package.subject }.version.name)
              .to eql version.name
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package2.subject }.version.name)
              .to eql version2.name
            expect(project_copy.work_packages.detect { |wp| wp.subject == work_package3.subject }.version)
              .to be_nil
          end
        end

        context "when work_package is assigned to somebody" do
          let(:assigned_user) do
            create(:user,
                   member_with_roles: { source => role })
          end

          before do
            work_package.update_column(:assigned_to_id, assigned_user.id)
          end

          context "with the members being copied" do
            let(:only_args) { %w[members work_packages] }

            it "copies the assigned_to" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].assigned_to)
                .to eql assigned_user
              # The assignee of the new work package receives a notification
              expect { perform_enqueued_jobs }
                .to change(Notification.where(recipient: assigned_user), :count)
                      .from(0)
                      .to(1)
            end
          end

          context "with the member being not copied" do
            let(:only_args) { %w[work_packages] }

            it "nils the assigned_to" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].assigned_to)
                .to be_nil
              # No notification is sent out
              expect { perform_enqueued_jobs }
                .not_to change(Notification.where(recipient: assigned_user), :count)
            end
          end
        end

        context "when work_package has a responsible person" do
          let(:responsible_user) do
            create(:user,
                   member_with_roles: { source => role })
          end

          before do
            work_package.update_column(:responsible_id, responsible_user.id)
          end

          context "with the members being copied" do
            let(:only_args) { %w[members work_packages] }

            it "copies the responsible" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].responsible)
                .to eql responsible_user
              # The responsible of the new work package receives a notification
              expect { perform_enqueued_jobs }
                .to change(Notification.where(recipient: responsible_user), :count)
                      .from(0)
                      .to(1)
            end
          end

          context "with the member being not copied" do
            let(:only_args) { %w[work_packages] }

            it "nils the assigned_to" do
              expect(subject).to be_success
              expect(project_copy.work_packages[0].responsible).to be_nil
              # No notification is sent out
              expect { perform_enqueued_jobs }
                .not_to change(Notification.where(recipient: responsible_user), :count)
            end
          end
        end

        describe "work package user custom field" do
          let(:custom_field) do
            create(:user_wp_custom_field).tap do |cf|
              source.work_package_custom_fields << cf
              work_package.type.custom_fields << cf
            end
          end

          before do
            custom_field
            # Void the custom field caching
            RequestStore.clear!
            work_package.send(custom_field.attribute_setter, current_user.id)
            work_package.save!(validate: false)
          end

          context "with the member being copied" do
            let(:only_args) { %w[members work_packages] }

            it "copies the custom_field" do
              expect(subject).to be_success
              wp = project_copy.work_packages.find_by(subject: work_package.subject)
              expect(wp.send(custom_field.attribute_getter)).to eql current_user
            end
          end

          context "with the member being not copied" do
            let(:only_args) { %w[work_packages] }

            it "nils the custom_field" do
              expect(subject).to be_success
              wp = project_copy.work_packages.find_by(subject: work_package.subject)
              expect(wp.send(custom_field.attribute_getter)).to be_nil
            end
          end
        end

        context("with work package relations",
                with_settings: { cross_project_work_package_relations: "1" }) do
          let!(:source_wp2) { create(:work_package, project: source, subject: "source wp2") }
          let!(:source_relation) { create(:relation, from: source_wp, to: source_wp2, relation_type: "relates") }

          let!(:other_project) { create(:project) }
          let!(:other_wp) { create(:work_package, project: other_project, subject: "other wp") }
          let!(:cross_relation) { create(:relation, from: source_wp, to: other_wp, relation_type: "duplicates") }

          it "copies relations" do
            expect(subject).to be_success

            expect(source.work_packages.count).to eq(project_copy.work_packages.count)
            copied_wp = project_copy.work_packages.find_by(subject: "source wp")
            copied_wp2 = project_copy.work_packages.find_by(subject: "source wp2")

            # First issue with a relation on project
            # copied relation + reflexive relation
            expect(copied_wp.relations.count).to eq 2
            relates_relation = copied_wp.relations.find { |r| r.relation_type == "relates" }
            expect(relates_relation.from_id).to eq copied_wp.id
            expect(relates_relation.to_id).to eq copied_wp2.id

            # Second issue with a cross project relation
            # copied relation + reflexive relation
            duplicates_relation = copied_wp.relations.find { |r| r.relation_type == "duplicates" }
            expect(duplicates_relation.from_id).to eq copied_wp.id
            expect(duplicates_relation.to_id).to eq other_wp.id
          end
        end
      end

      context "with wiki" do
        let(:only_args) { %i[wiki] }

        it "copies wiki menu items" do
          source.wiki.wiki_menu_items << create(:wiki_menu_item_with_parent, wiki: source.wiki)

          expect(subject).to be_success
          expect(project_copy.wiki.wiki_menu_items.count).to eq 3
        end

        it "ignores wiki attachments" do
          create(:attachment, container: source_wiki_page)
          expect(source_wiki_page.attachments.count).to eq(1)

          expect(subject).to be_success
          expect(subject.errors).to be_empty
          expect(project_copy.wiki.pages.count).to eq 2

          page = project_copy.wiki.pages.find_by(title: source_wiki_page.title)
          expect(page.attachments.count).to eq(0)
        end

        context "when wiki attachments are requested" do
          let(:only_args) { %i[wiki wiki_page_attachments] }

          it "copies them" do
            create(:attachment, container: source_wiki_page)
            expect(source_wiki_page.attachments.count).to eq(1)

            expect(subject).to be_success
            expect(subject.errors).to be_empty
            expect(project_copy.wiki.pages.count).to eq 2

            page = project_copy.wiki.pages.find_by(title: source_wiki_page.title)
            expect(page.attachments.count).to eq(1)
            expect(page.attachments.first.author).to eql(current_user)
          end
        end
      end
    end

    context "without anything selected" do
      let!(:source_member) { create(:user, member_with_roles: { source => role }) }
      let(:only_args) { nil }

      # rubocop:disable RSpec/MultipleExpectations
      it "sets attributes only without copying dependencies" do
        expect(subject).to be_success

        expect(project_copy.members.count).to eq 1
        expect(project_copy.categories.count).to eq 0
        expect(project_copy.work_packages.count).to eq 0
        expect(project_copy.forums.count).to eq 0
        # Default wiki page
        expect(project_copy.wiki).to be_present
        expect(project_copy.wiki.pages.count).to eq 0
        expect(project_copy.wiki.wiki_menu_items.count).to eq 1
        expect(project_copy.queries.count).to eq 0
        expect(project_copy.versions.count).to eq 0

        # Cleared attributes
        expect(project_copy).to be_persisted
        expect(project_copy.name).to eq "Target Project Name"
        expect(project_copy.name).to eq "Target Project Name"
        expect(project_copy.identifier).to eq "some-identifier"

        # Duplicated attributes
        expect(project_copy.description).to eq source.description
        expect(source.enabled_module_names.sort - %w[repository]).to eq project_copy.enabled_module_names.sort
        expect(project_copy.types).to eq source.types

        # Default attributes
        expect(project_copy).to be_active

        # Copy only the current_user as we do not copy any members
        # Only the default role is being assigned according to setting
        member = project_copy.reload.members.first
        expect(member.principal)
          .to eql(current_user)
        expect(member.roles)
          .to contain_exactly(new_project_role)
      end
      # rubocop:enable RSpec/MultipleExpectations

      context "with group memberships" do
        let!(:user) { create(:user) }
        let!(:another_role) { create(:project_role) }
        let!(:group) do
          create(:group, members: [user])
        end

        it "does not copy group members" do
          Members::CreateService
            .new(user: current_user, contract_class: EmptyContract)
            .call(principal: group, roles: [another_role], project: source)

          source.users.reload
          expect(source.users).to include current_user
          expect(source.users).to include user
          expect(project_copy.groups).to be_empty
          expect(source.member_principals.count).to eq 4

          expect(subject).to be_success

          expect(project_copy.member_principals.count).to eq 1
          expect(project_copy.groups).to be_empty
          expect(project_copy.users).to contain_exactly current_user

          group_member = Member.find_by(user_id: group.id, project_id: project_copy.id)
          expect(group_member).to be_nil

          member = Member.find_by(user_id: user.id, project_id: project_copy.id)
          expect(member).to be_nil
        end
      end

      it_behaves_like "copies public attribute"
      it_behaves_like "copies custom fields"
    end
  end
end
