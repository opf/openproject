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

RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper

  let(:member) { build_stubbed(:user) }
  let(:current_user) { member }
  let(:embed_links) { true }
  let(:timestamps) { nil }
  let(:query) { nil }
  let(:representer) do
    described_class.create(work_package, current_user:, embed_links:, timestamps:, query:)
  end
  let(:parent) { nil }
  let(:priority) { build_stubbed(:priority, updated_at: Time.zone.now) }
  let(:assignee) { nil }
  let(:responsible) { nil }
  let(:schedule_manually) { nil }
  let(:start_date) { Time.zone.today.to_datetime }
  let(:due_date) { Time.zone.today.to_datetime }
  let(:type_milestone) { false }
  let(:estimated_hours) { nil }
  let(:derived_estimated_hours) { nil }
  let(:spent_hours) { 0 }
  let(:derived_start_date) { Time.zone.today - 4.days }
  let(:derived_due_date) { Time.zone.today - 5.days }
  let(:budget) { build_stubbed(:budget, project:) }
  let(:duration) { nil }
  let(:ignore_non_working_days) { true }
  let(:work_package) do
    build_stubbed(:work_package,
                  schedule_manually:,
                  start_date:,
                  due_date:,
                  duration:,
                  done_ratio: 50,
                  parent:,
                  type:,
                  project:,
                  priority:,
                  assigned_to: assignee,
                  responsible:,
                  estimated_hours:,
                  derived_estimated_hours:,
                  budget:,
                  ignore_non_working_days:,
                  status:) do |wp|
      allow(wp).to receive_messages(available_custom_fields:,
                                    spent_hours:,
                                    derived_start_date:,
                                    derived_due_date:)
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
      view_file_links
      manage_file_links
      delete_work_packages
    ]
  end
  let(:permissions) { all_permissions }
  let(:project) { build_stubbed(:project_with_types) }
  let(:type) do
    type = project.types.first

    type.is_milestone = type_milestone

    type
  end
  let(:status) { build_stubbed(:status, updated_at: Time.zone.now) }
  let(:available_custom_fields) { [] }

  before do
    login_as current_user

    mock_permissions_for(current_user) do |mock|
      permissions.each do |permission|
        perm = OpenProject::AccessControl.permission(permission)
        mock.allow_globally perm.name if perm.global?
        mock.allow_in_project perm.name, project: project if perm.project?
      end
    end
  end

  describe ".new" do
    it "is prevented as .create is to be used" do
      expect { described_class.new(work_package, current_user:, embed_links:) }
        .to raise_error NoMethodError
    end
  end

  include_context "eager loaded work package representer"

  describe "generation" do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json("WorkPackage".to_json).at_path("_type") }

    describe "work_package" do
      it { is_expected.to have_json_path("id") }

      it_behaves_like "API V3 formattable", "description" do
        let(:format) { "markdown" }
        let(:raw) { work_package.description }
        let(:html) { "<p class=\"op-uc-p\">#{work_package.description}</p>" }
      end

      describe "scheduleManually" do
        context "when no value" do
          it "renders as false (default value)" do
            expect(subject).to be_json_eql(false.to_json).at_path("scheduleManually")
          end
        end

        context "when false" do
          let(:schedule_manually) { false }

          it "renders as false" do
            expect(subject).to be_json_eql(false.to_json).at_path("scheduleManually")
          end
        end

        context "when true" do
          let(:schedule_manually) { true }

          it "renders as true" do
            expect(subject).to be_json_eql(true.to_json).at_path("scheduleManually")
          end
        end
      end

      describe "startDate" do
        it_behaves_like "has ISO 8601 date only" do
          let(:date) { start_date }
          let(:json_path) { "startDate" }
        end

        context "when it's nil" do
          let(:start_date) { nil }

          it "renders as null" do
            expect(subject).to be_json_eql(nil.to_json).at_path("startDate")
          end
        end

        context "when the work package has a milestone type" do
          let(:type_milestone) { true }

          it "has no startDate" do
            expect(subject).not_to have_json_path("startDate")
          end
        end
      end

      describe "dueDate" do
        context "with a non milestone type" do
          it_behaves_like "has ISO 8601 date only" do
            let(:date) { work_package.due_date }
            let(:json_path) { "dueDate" }
          end

          context "with no finish date" do
            let(:due_date) { nil }

            it "renders as null" do
              expect(subject).to be_json_eql(nil.to_json).at_path("dueDate")
            end
          end
        end

        context "with a milestone type" do
          let(:type_milestone) { true }

          it "with no startDate" do
            expect(subject).not_to have_json_path("dueDate")
          end
        end
      end

      describe "date" do
        context "with a milestone type" do
          let(:type_milestone) { true }

          it_behaves_like "has ISO 8601 date only" do
            let(:date) { due_date } # could just as well be start_date
            let(:json_path) { "date" }
          end

          context "with no finish date" do
            let(:due_date) { nil }

            it "renders as null" do
              expect(subject).to be_json_eql(nil.to_json).at_path("date")
            end
          end
        end

        context "with not a milestone type" do
          it "with no date" do
            expect(subject).not_to have_json_path("date")
          end
        end
      end

      describe "derivedStartDate" do
        it_behaves_like "has ISO 8601 date only" do
          let(:date) { derived_start_date }
          let(:json_path) { "derivedStartDate" }
        end

        context "with no derived start date" do
          let(:derived_start_date) { nil }

          it "renders as null" do
            expect(subject)
              .to be_json_eql(nil.to_json)
                    .at_path("derivedStartDate")
          end
        end

        context "when the work package has a milestone type" do
          let(:type_milestone) { true }

          it "with no derivedStartDate" do
            expect(subject)
              .not_to have_json_path("derivedStartDate")
          end
        end
      end

      describe "derivedDueDate" do
        it_behaves_like "has ISO 8601 date only" do
          let(:date) { derived_due_date }
          let(:json_path) { "derivedDueDate" }
        end

        context "with no derived due date" do
          let(:derived_due_date) { nil }

          it "renders as null" do
            expect(subject)
              .to be_json_eql(nil.to_json)
                    .at_path("derivedDueDate")
          end
        end

        context "when the work package has a milestone type" do
          let(:type_milestone) { true }

          it "with no derivedDueDate" do
            expect(subject)
              .not_to have_json_path("derivedDueDate")
          end
        end
      end

      describe "duration" do
        let(:duration) { 6 }

        it { is_expected.to be_json_eql("P6D".to_json).at_path("duration") }

        context "with no duration" do
          let(:duration) { nil }

          it "renders as null" do
            expect(subject).to be_json_eql(nil.to_json).at_path("duration")
          end
        end

        context "when the work_package is a milestone" do
          let(:type_milestone) { true }

          it "with no duration" do
            expect(subject).not_to have_json_path("duration")
          end
        end
      end

      describe "ignoreNonWorkingDays" do
        let(:ignore_non_working_days) { true }

        context "with the value being `true`" do
          it { is_expected.to be_json_eql(true.to_json).at_path("ignoreNonWorkingDays") }
        end

        context "with the value being `false`" do
          let(:ignore_non_working_days) { false }

          it { is_expected.to be_json_eql(false.to_json).at_path("ignoreNonWorkingDays") }
        end
      end

      describe "createdAt" do
        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { work_package.created_at }
          let(:json_path) { "createdAt" }
        end
      end

      describe "updatedAt" do
        it_behaves_like "has UTC ISO 8601 date and time" do
          let(:date) { work_package.updated_at }
          let(:json_path) { "updatedAt" }
        end
      end

      it { is_expected.to have_json_path("subject") }

      describe "lock version" do
        it { is_expected.to have_json_path("lockVersion") }

        it { is_expected.to have_json_type(Integer).at_path("lockVersion") }

        it { is_expected.to be_json_eql(work_package.lock_version.to_json).at_path("lockVersion") }
      end

      describe "readonly" do
        context "with no status" do
          let(:status) { nil }

          it "renders nothing" do
            expect(subject).not_to have_json_path("readonly")
          end
        end

        context "when false", with_ee: %i[readonly_work_packages] do
          let(:status) { build_stubbed(:status, is_readonly: false) }

          it "renders as false" do
            expect(subject).to be_json_eql(false.to_json).at_path("readonly")
          end
        end

        context "when true", with_ee: %i[readonly_work_packages] do
          let(:status) { build_stubbed(:status, is_readonly: true) }

          it "renders as true" do
            expect(subject).to be_json_eql(true.to_json).at_path("readonly")
          end
        end
      end
    end

    describe "estimatedTime" do
      let(:estimated_hours) { 6.5 }

      it { is_expected.to be_json_eql("PT6H30M".to_json).at_path("estimatedTime") }
    end

    describe "derivedEstimatedTime" do
      let(:derived_estimated_hours) { 3.75 }

      it { is_expected.to be_json_eql("PT3H45M".to_json).at_path("derivedEstimatedTime") }
    end

    xdescribe "spentTime" do
      # spentTime is completely overwritten by costs
      # TODO: move specs from costs to here
    end

    describe "percentageDone" do
      describe "work package done ratio setting behavior" do
        context "when setting enabled" do
          it { expect(parse_json(subject)["percentageDone"]).to eq(50) }
        end
      end
    end

    describe "custom fields" do
      let(:available_custom_fields) { [build_stubbed(:integer_wp_custom_field)] }

      it "uses a CustomFieldInjector" do
        allow(API::V3::Utilities::CustomFieldInjector).to receive(:create_value_representer).and_call_original
        representer.to_json
        expect(API::V3::Utilities::CustomFieldInjector).to have_received(:create_value_representer)
      end
    end

    describe "_links" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { "/api/v3/work_packages/#{work_package.id}" }
        let(:title) { work_package.subject }
      end

      describe "update links" do
        describe "update by form" do
          it_behaves_like "has an untitled link" do
            let(:link) { "update" }
            let(:href) { api_v3_paths.work_package_form(work_package.id) }
          end

          it "is a post link" do
            expect(subject).to be_json_eql("post".to_json).at_path("_links/update/method")
          end
        end

        describe "immediate update" do
          it_behaves_like "has an untitled link" do
            let(:link) { "updateImmediately" }
            let(:href) { api_v3_paths.work_package(work_package.id) }
          end

          it "is a patch link" do
            expect(subject).to be_json_eql("patch".to_json).at_path("_links/updateImmediately/method")
          end
        end

        context "when user is not allowed to edit work packages" do
          let(:permissions) { all_permissions - [:edit_work_packages] }

          it_behaves_like "has no link" do
            let(:link) { "update" }
          end

          it_behaves_like "has no link" do
            let(:link) { "updateImmediately" }
          end
        end

        context "when user lacks edit permission but has assign_versions" do
          let(:permissions) { all_permissions - [:edit_work_packages] + [:assign_versions] }

          it_behaves_like "has an untitled link" do
            let(:link) { "update" }
            let(:href) { api_v3_paths.work_package_form(work_package.id) }
          end

          it_behaves_like "has an untitled link" do
            let(:link) { "updateImmediately" }
            let(:href) { api_v3_paths.work_package(work_package.id) }
          end
        end

        context "when user lacks edit permission but has change_work_package_status" do
          let(:permissions) { all_permissions - [:edit_work_packages] + [:change_work_package_status] }

          it_behaves_like "has an untitled link" do
            let(:link) { "update" }
            let(:href) { api_v3_paths.work_package_form(work_package.id) }
          end

          it_behaves_like "has an untitled link" do
            let(:link) { "updateImmediately" }
            let(:href) { api_v3_paths.work_package(work_package.id) }
          end
        end
      end

      describe "status" do
        it_behaves_like "has a titled link" do
          let(:link) { "status" }
          let(:href) { "/api/v3/statuses/#{work_package.status_id}" }
          let(:title) { work_package.status.name }
        end
      end

      describe "type" do
        it_behaves_like "has a titled link" do
          let(:link) { "type" }
          let(:href) { "/api/v3/types/#{work_package.type_id}" }
          let(:title) { work_package.type.name }
        end
      end

      describe "author" do
        it_behaves_like "has a titled link" do
          let(:link) { "author" }
          let(:href) { "/api/v3/users/#{work_package.author.id}" }
          let(:title) { work_package.author.name }
        end
      end

      describe "assignee" do
        context "as a user" do
          let(:assignee) { build_stubbed(:user) }

          it_behaves_like "has a titled link" do
            let(:link) { "assignee" }
            let(:href) { "/api/v3/users/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context "as a group" do
          let(:assignee) { build_stubbed(:group) }

          it_behaves_like "has a titled link" do
            let(:link) { "assignee" }
            let(:href) { "/api/v3/groups/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context "as a placeholder user" do
          let(:assignee) { build_stubbed(:placeholder_user) }

          it_behaves_like "has a titled link" do
            let(:link) { "assignee" }
            let(:href) { "/api/v3/placeholder_users/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context "as a deleted user" do
          let(:assignee) { build_stubbed(:deleted_user) }

          it_behaves_like "has a titled link" do
            let(:link) { "assignee" }
            let(:href) { "/api/v3/users/#{work_package.assigned_to.id}" }
            let(:title) { work_package.assigned_to.name }
          end
        end

        context "as not set" do
          it_behaves_like "has an empty link" do
            let(:link) { "assignee" }
          end
        end
      end

      describe "responsible" do
        context "as a user" do
          let(:responsible) { build_stubbed(:user) }

          it_behaves_like "has a titled link" do
            let(:link) { "responsible" }
            let(:href) { "/api/v3/users/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context "as a group" do
          let(:responsible) { build_stubbed(:group) }

          it_behaves_like "has a titled link" do
            let(:link) { "responsible" }
            let(:href) { "/api/v3/groups/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context "as a placeholder user" do
          let(:responsible) { build_stubbed(:placeholder_user) }

          it_behaves_like "has a titled link" do
            let(:link) { "responsible" }
            let(:href) { "/api/v3/placeholder_users/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context "as a deleted user" do
          let(:responsible) { build_stubbed(:deleted_user) }

          it_behaves_like "has a titled link" do
            let(:link) { "responsible" }
            let(:href) { "/api/v3/users/#{work_package.responsible.id}" }
            let(:title) { work_package.responsible.name }
          end
        end

        context "as not set" do
          it_behaves_like "has an empty link" do
            let(:link) { "responsible" }
          end
        end
      end

      describe "revisions" do
        it_behaves_like "has an untitled link" do
          let(:link) { "revisions" }
          let(:href) do
            api_v3_paths.work_package_revisions(work_package.id)
          end
        end

        context "when user lacks the view_changesets permission" do
          let(:permissions) { all_permissions - [:view_changesets] }

          it_behaves_like "has no link" do
            let(:link) { "revisions" }
          end
        end
      end

      describe "version" do
        let(:embedded_path) { "_embedded/version" }
        let(:href_path) { "_links/version/href" }

        context "when no version set" do
          it_behaves_like "has an empty link" do
            let(:link) { "version" }
          end
        end

        context "when version is set" do
          let!(:version) { create(:version, project:) }

          before do
            work_package.version = version
          end

          it_behaves_like "has a titled link" do
            let(:link) { "version" }
            let(:href) { api_v3_paths.version(version.id) }
            let(:title) { version.to_s }
          end

          it "has the version embedded" do
            expect(subject).to be_json_eql("Version".to_json).at_path("#{embedded_path}/_type")
            expect(subject).to be_json_eql(version.name.to_json).at_path("#{embedded_path}/name")
          end
        end
      end

      describe "project" do
        let(:embedded_path) { "_embedded/project" }
        let(:href_path) { "_links/project/href" }

        it_behaves_like "has a titled link" do
          let(:link) { "project" }
          let(:href) { api_v3_paths.project(project.id) }
          let(:title) { project.name }
        end

        it "has the project embedded" do
          expect(subject).to be_json_eql("Project".to_json).at_path("#{embedded_path}/_type")
          expect(subject).to be_json_eql(project.name.to_json).at_path("#{embedded_path}/name")
        end
      end

      describe "category" do
        let(:embedded_path) { "_embedded/category" }
        let(:href_path) { "_links/category/href" }

        context "when no category set" do
          it_behaves_like "has an empty link" do
            let(:link) { "category" }
          end
        end

        context "when category is set" do
          let!(:category) { build_stubbed(:category) }

          before do
            work_package.category = category
          end

          it_behaves_like "has a titled link" do
            let(:link) { "category" }
            let(:href) { api_v3_paths.category(category.id) }
            let(:title) { category.name }
          end

          it "has the category embedded" do
            expect(subject).to have_json_type(Hash).at_path("_embedded/category")
            expect(subject).to be_json_eql("Category".to_json).at_path("#{embedded_path}/_type")
            expect(subject).to be_json_eql(category.name.to_json).at_path("#{embedded_path}/name")
          end
        end
      end

      describe "priority" do
        it_behaves_like "has a titled link" do
          let(:link) { "priority" }
          let(:href) { api_v3_paths.priority(priority.id) }
          let(:title) { priority.name }
        end

        it "has the priority embedded" do
          expect(subject).to be_json_eql("Priority".to_json).at_path("_embedded/priority/_type")
          expect(subject).to be_json_eql(priority.name.to_json).at_path("_embedded/priority/name")
        end
      end

      describe "budget" do
        context "with the user having the view_budgets permission" do
          let(:permissions) { [:view_budgets] }

          it_behaves_like "has a titled link" do
            let(:link) { "budget" }
            let(:href) { "/api/v3/budgets/#{budget.id}" }
            let(:title) { budget.subject }
          end

          it "has the budget embedded" do
            expect(subject)
              .to be_json_eql(budget.subject.to_json)
                    .at_path("_embedded/budget/subject")
          end
        end

        context "with the user lacking the view_budgets permission" do
          it "has no link to the budget" do
            expect(subject)
              .not_to have_json_path("_links/budget")
          end

          it "has no budget embedded" do
            expect(subject)
              .not_to have_json_path("_embedded/budget")
          end
        end
      end

      describe "schema" do
        it_behaves_like "has an untitled link" do
          let(:link) { "schema" }
          let(:href) do
            api_v3_paths.work_package_schema(work_package.project.id, work_package.type.id)
          end
        end
      end

      describe "attachments" do
        it_behaves_like "has an untitled link" do
          let(:link) { "attachments" }
          let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
        end

        it "embeds the attachments as collection" do
          expect(subject).to be_json_eql("Collection".to_json).at_path("_embedded/attachments/_type")
        end

        it_behaves_like "has an untitled link" do
          let(:link) { "addAttachment" }
          let(:href) { api_v3_paths.attachments_by_work_package(work_package.id) }
        end

        context "when work package blocked" do
          before do
            allow(work_package).to receive(:readonly_status?).and_return true
          end

          it_behaves_like "has no link" do
            let(:link) { "addAttachment" }
          end
        end

        it "addAttachments is a post link" do
          expect(subject).to be_json_eql("post".to_json).at_path("_links/addAttachment/method")
        end

        context "when user is not allowed to edit work packages" do
          let(:permissions) { all_permissions - %i[edit_work_packages] }

          it_behaves_like "has no link" do
            let(:link) { "addAttachment" }
          end
        end
      end

      describe "fileLinks" do
        it_behaves_like "has an untitled link" do
          let(:link) { "fileLinks" }
          let(:href) { api_v3_paths.file_links(work_package.id) }
        end

        it_behaves_like "has an untitled action link" do
          let(:permission) { :manage_file_links }
          let(:link) { "addFileLink" }
          let(:href) { api_v3_paths.file_links(work_package.id) }
          let(:method) { "post" }
        end

        context "when user has no permission to view file links" do
          let(:permissions) { all_permissions - %i[view_file_links] }

          it_behaves_like "has no link" do
            let(:link) { "fileLinks" }
          end
        end
      end

      context "when the user is not watching the work package" do
        it "has a link to watch" do
          expect(subject)
            .to be_json_eql(api_v3_paths.work_package_watchers(work_package.id).to_json)
                  .at_path("_links/watch/href")
        end

        it "does not have a link to unwatch" do
          expect(subject).not_to have_json_path("_links/unwatch/href")
        end
      end

      context "when the user is watching the work package" do
        let(:watchers) { [build_stubbed(:watcher, watchable: work_package, user: current_user)] }

        before do
          allow(work_package)
            .to receive(:watchers)
                  .and_return(watchers)
        end

        it "has a link to unwatch" do
          expect(subject)
            .to be_json_eql(api_v3_paths.watcher(current_user.id, work_package.id).to_json)
                  .at_path("_links/unwatch/href")
        end

        it "does not have a link to watch" do
          expect(subject).not_to have_json_path("_links/watch/href")
        end
      end

      context "when the user has permission to add comments" do
        it "has a link to add comment" do
          expect(subject).to have_json_path("_links/addComment")
        end
      end

      context "when the user does not have the permission to add comments" do
        let(:permissions) { all_permissions - [:add_work_package_notes] }

        it "does not have a link to add comment" do
          expect(subject).not_to have_json_path("_links/addComment/href")
        end
      end

      context "when the user has the permission to add and remove watchers" do
        it "has a link to add watcher" do
          expect(subject).to be_json_eql(
            api_v3_paths.work_package_watchers(work_package.id).to_json
          )
            .at_path("_links/addWatcher/href")
        end

        it "has a link to remove watcher" do
          expect(subject).to be_json_eql(
            api_v3_paths.watcher("{user_id}", work_package.id).to_json
          )
            .at_path("_links/removeWatcher/href")
        end
      end

      context "when the user does not have the permission to add watchers" do
        let(:permissions) { all_permissions - [:add_work_package_watchers] }

        it "does not have a link to add watcher" do
          expect(subject).not_to have_json_path("_links/addWatcher/href")
        end
      end

      context "when the user does not have the permission to remove watchers" do
        let(:permissions) { all_permissions - [:delete_work_package_watchers] }

        it "does not have a link to remove watcher" do
          expect(subject).not_to have_json_path("_links/removeWatcher/href")
        end
      end

      describe "watchers link" do
        context "when the user is allowed to see watchers" do
          it_behaves_like "has an untitled link" do
            let(:link) { "watchers" }
            let(:href) { api_v3_paths.work_package_watchers work_package.id }
          end
        end

        context "when the user is not allowed to see watchers" do
          let(:permissions) { all_permissions - [:view_work_package_watchers] }

          it_behaves_like "has no link" do
            let(:link) { "watchers" }
          end
        end
      end

      describe "relations" do
        it_behaves_like "has an untitled link" do
          let(:link) { "relations" }
          let(:href) { "/api/v3/work_packages/#{work_package.id}/relations" }
        end

        context "when the user has the permission to manage relations" do
          it "has a link to add relation" do
            expect(subject).to have_json_path("_links/addRelation/href")
          end
        end

        context "when the user does not have the permission to manage relations" do
          let(:permissions) { all_permissions - [:manage_work_package_relations] }

          it "does not have a link to add relation" do
            expect(subject).not_to have_json_path("_links/addRelation/href")
          end
        end
      end

      context "when the user has the permission to add work packages" do
        it "has a link to add child" do
          expect(subject).to be_json_eql("/api/v3/projects/#{project.identifier}/work_packages".to_json)
                               .at_path("_links/addChild/href")
        end
      end

      context "when the user does not have the permission to add work packages" do
        let(:permissions) { all_permissions - [:add_work_packages] }

        it "does not have a link to add child" do
          expect(subject).not_to have_json_path("_links/addChild/href")
        end
      end

      describe "timeEntries" do
        context "when the user has the permission to view time entries" do
          it_behaves_like "has a titled link" do
            let(:link) { "timeEntries" }
            let(:href) do
              api_v3_paths.path_for(:time_entries,
                                    filters: [{ work_package_id: { operator: "=", values: [work_package.id.to_s] } }])
            end
            let(:title) { "Time entries" }
          end
        end

        context "when the user does not have the permission to view time entries" do
          let(:permissions) { all_permissions - [:view_time_entries] }

          it "does not have a link to timeEntries" do
            expect(subject).not_to have_json_path("_links/timeEntries/href")
          end
        end
      end

      describe "linked relations" do
        let(:project) { create(:project, public: false) }
        let(:forbidden_project) { create(:project, public: false) }
        let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }

        before do
          login_as(user)
          allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)
        end

        describe "parent" do
          let(:visible_parent) do
            build_stubbed(:work_package) do |wp|
              allow(wp)
                .to receive(:visible?)
                      .and_return(true)
            end
          end
          let(:invisible_parent) do
            build_stubbed(:work_package) do |wp|
              allow(wp)
                .to receive(:visible?)
                      .and_return(false)
            end
          end

          context "with no parent" do
            it_behaves_like "has an empty link" do
              let(:link) { "parent" }
            end
          end

          context "when parent is visible" do
            let(:parent) { visible_parent }

            it_behaves_like "has a titled link" do
              let(:link) { "parent" }
              let(:href) { api_v3_paths.work_package(visible_parent.id) }
              let(:title) { visible_parent.subject }
            end
          end

          context "when parent not visible" do
            let(:parent) { invisible_parent }

            it_behaves_like "has an empty link" do
              let(:link) { "parent" }
            end
          end
        end

        describe "ancestors" do
          let(:root) { build_stubbed(:work_package, project:) }
          let(:intermediate) do
            build_stubbed(:work_package, parent: root, project:)
          end

          context "when ancestors are visible" do
            before do
              allow(work_package).to receive(:visible_ancestors)
                                       .and_return([root, intermediate])
            end

            it "renders two items in ancestors" do
              expect(subject).to have_json_size(2).at_path("_links/ancestors")
              expect(parse_json(subject)["_links"]["ancestors"][0]["title"])
                .to eq(root.subject)
              expect(parse_json(subject)["_links"]["ancestors"][1]["title"])
                .to eq(intermediate.subject)
              expect(work_package).to have_received(:visible_ancestors)
            end
          end

          context "when ancestors are invisible" do
            before do
              allow(work_package).to receive(:visible_ancestors)
                                       .and_return([])
            end

            it "renders empty ancestors" do
              expect(subject).to have_json_size(0).at_path("_links/ancestors")
              expect(work_package).to have_received(:visible_ancestors)
            end
          end
        end

        describe "children" do
          let(:work_package) { create(:work_package, project:) }
          let!(:forbidden_work_package) do
            create(:work_package,
                   project: forbidden_project,
                   parent: work_package)
          end

          it { expect(subject).not_to have_json_path("_links/children") }

          describe "visible and invisible children" do
            let!(:child) do
              create(:work_package,
                     project:,
                     parent: work_package)
            end

            it { expect(subject).to have_json_size(1).at_path("_links/children") }

            it do
              expect(parse_json(subject)["_links"]["children"][0]["title"]).to eq(child.subject)
            end
          end
        end
      end

      it_behaves_like "has an untitled action link" do
        let(:link) { "delete" }
        let(:href) { api_v3_paths.work_package(work_package.id) }
        let(:method) { :delete }
        let(:permission) { :delete_work_packages }
      end

      describe "logTime" do
        it_behaves_like "has a titled action link" do
          let(:link) { "logTime" }
          let(:permission) { %i(log_time log_own_time) }
          let(:href) { api_v3_paths.time_entries }
          let(:title) { "Log time on work package '#{work_package.subject}'" }
        end
      end

      describe "move" do
        it_behaves_like "has a titled action link" do
          let(:link) { "move" }
          let(:href) { work_package_path(work_package, "move/new") }
          let(:permission) { :move_work_packages }
          let(:title) { "Move work package '#{work_package.subject}'" }
        end
      end

      describe "copy" do
        it_behaves_like "has a titled action link" do
          let(:link) { "copy" }
          let(:href) { work_package_path(work_package, "copy") }
          let(:permission) { :add_work_packages }
          let(:title) { "Copy work package '#{work_package.subject}'" }
        end
      end

      describe "pdf" do
        it_behaves_like "has a titled action link" do
          let(:link) { "pdf" }
          let(:permission) { :export_work_packages }
          let(:href) { "/work_packages/#{work_package.id}.pdf" }
          let(:title) { "Export as PDF" }
        end
      end

      describe "atom" do
        context "with feeds enabled", with_settings: { feeds_enabled?: true } do
          it_behaves_like "has a titled action link" do
            let(:link) { "atom" }
            let(:permission) { :export_work_packages }
            let(:href) { "/work_packages/#{work_package.id}.atom" }
            let(:title) { "Atom feed" }
          end
        end

        context "with feeds disabled", with_settings: { feeds_enabled?: false } do
          let(:permissions) { all_permissions + [:export_work_packages] }

          it_behaves_like "has no link" do
            let(:link) { "atom" }
          end
        end
      end

      describe "changeParent" do
        it_behaves_like "has a titled action link" do
          let(:link) { "changeParent" }
          let(:href) { api_v3_paths.work_package(work_package.id) }
          let(:permission) { :manage_subtasks }
          let(:title) { "Change parent of #{work_package.subject}" }
          let(:method) { :patch }
        end
      end

      describe "availableWatchers" do
        it_behaves_like "has an untitled action link" do
          let(:link) { "availableWatchers" }
          let(:href) { api_v3_paths.available_watchers(work_package.id) }
          let(:permission) { :add_work_package_watchers }
        end
      end

      describe "customFields" do
        it_behaves_like "has a titled action link" do
          let(:link) { "customFields" }
          let(:permission) { :select_custom_fields }
          let(:href) { project_settings_custom_fields_path(work_package.project.identifier) }
          let(:title) { "Custom fields" }
        end
      end

      describe "formConfiguration" do
        context "when not admin" do
          it_behaves_like "has no link" do
            let(:link) { "formConfiguration" }
          end
        end

        context "when admin" do
          let(:current_user) { build_stubbed(:admin) }

          it_behaves_like "has a titled link" do
            let(:link) { "configureForm" }
            let(:href) { edit_type_path(work_package.type_id, tab: "form_configuration") }
            let(:title) { "Configure form" }
          end
        end
      end

      describe "customActions" do
        it "has a collection of customActions" do
          unassign_action = build_stubbed(:custom_action,
                                          actions: [CustomActions::Actions::AssignedTo.new(value: nil)],
                                          name: "Unassign")
          allow(work_package)
            .to receive(:custom_actions)
                  .and_return([unassign_action])

          expected = [
            {
              href: api_v3_paths.custom_action(unassign_action.id),
              title: unassign_action.name
            }
          ]

          expect(subject)
            .to be_json_eql(expected.to_json)
                  .at_path("_links/customActions")
        end
      end
    end

    describe "_embedded" do
      it { is_expected.to have_json_type(Object).at_path("_embedded") }

      describe "status" do
        it { is_expected.to have_json_path("_embedded/status") }

        it { is_expected.to be_json_eql("Status".to_json).at_path("_embedded/status/_type") }

        it { is_expected.to be_json_eql(status.name.to_json).at_path("_embedded/status/name") }

        it {
          expect(subject).to be_json_eql(status.is_closed.to_json).at_path("_embedded/status/isClosed")
        }
      end

      describe "activities" do
        it "is not embedded" do
          expect(subject).not_to have_json_path("_embedded/activities")
        end
      end

      describe "relations" do
        let(:relation) do
          build_stubbed(:relation,
                        from: work_package)
        end

        before do
          scope = instance_double(ActiveRecord::Relation)

          allow(work_package)
            .to receive(:visible_relations)
                  .with(current_user)
                  .and_return(scope)
          allow(scope)
            .to receive(:includes)
                  .and_return([relation])
        end

        it "embeds a collection" do
          expect(subject)
            .to be_json_eql("Collection".to_json)
                  .at_path("_embedded/relations/_type")
        end

        it "embeds with an href containing the work_package" do
          expect(subject)
            .to be_json_eql(api_v3_paths.work_package_relations(work_package.id).to_json)
                  .at_path("_embedded/relations/_links/self/href")
        end

        it "embeds the visible relations" do
          expect(subject)
            .to be_json_eql(1.to_json)
                  .at_path("_embedded/relations/total")

          expect(subject)
            .to be_json_eql(api_v3_paths.relation(relation.id).to_json)
                  .at_path("_embedded/relations/_embedded/elements/0/_links/self/href")
        end
      end

      describe "fileLinks" do
        let(:storage) { build_stubbed(:nextcloud_storage) }
        let(:file_link) { build_stubbed(:file_link, storage:, container: work_package) }

        before do
          allow(work_package).to receive(:file_links).and_return([file_link])
        end

        it "embeds a collection" do
          expect(subject)
            .to be_json_eql("Collection".to_json)
                  .at_path("_embedded/fileLinks/_type")
        end

        it "embeds with an href containing the work_package" do
          expect(subject)
            .to be_json_eql(api_v3_paths.file_links(work_package.id).to_json)
                  .at_path("_embedded/fileLinks/_links/self/href")
        end

        it "embeds the visible file links" do
          expect(subject)
            .to be_json_eql(1.to_json)
                  .at_path("_embedded/fileLinks/total")

          expect(subject)
            .to be_json_eql(api_v3_paths.file_link(file_link.id).to_json)
                  .at_path("_embedded/fileLinks/_embedded/elements/0/_links/self/href")
        end
      end

      describe "customActions" do
        it "has an array of customActions" do
          unassign_action = build_stubbed(:custom_action,
                                          actions: [CustomActions::Actions::AssignedTo.new(value: nil)],
                                          name: "Unassign")
          allow(work_package)
            .to receive(:custom_actions)
                  .and_return([unassign_action])

          expect(subject)
            .to be_json_eql("Unassign".to_json)
                  .at_path("_embedded/customActions/0/name")
        end
      end

      context "when passing timestamps" do
        let(:timestamps) { [Timestamp.new(baseline_time), Timestamp.now] }
        let(:baseline_time) { Time.zone.parse("2022-01-01") }
        let(:work_pacakges) { WorkPackage.where(id: work_package.id) }
        let(:work_package) do
          create(:work_package,
                 subject: "The current work package",
                 assigned_to: current_user,
                 project:,
                 journals: {
                   baseline_time - 1.day => { subject: "The original work package" },
                   1.day.ago => {}
                 })
        end
        let(:project) { create(:project) }

        current_user do
          create(:user,
                 firstname: "user",
                 lastname: "1",
                 member_with_permissions: { project => %i[view_work_packages view_file_links] })
        end

        before do
          # Usually the eager loading wrapper is mocked
          # in spec/support/api/v3/work_packages/work_package_representer_eager_loading.rb.
          # However, I feel more comfortable if we test the real thing here.
          #
          allow(API::V3::WorkPackages::WorkPackageEagerLoadingWrapper)
            .to receive(:wrap_one)
                  .and_call_original
        end

        describe "attributesByTimestamp" do
          it "has an array" do
            expect(JSON.parse(subject)["_embedded"]["attributesByTimestamp"]).to be_an Array
          end

          it "has the historic attributes for each timestamp when they differ from the current attributes" do
            expect(subject)
              .to be_json_eql("The original work package".to_json)
                    .at_path("_embedded/attributesByTimestamp/0/subject")
          end

          it "skips the historic attributes when they are the same as the current attributes" do
            expect(subject)
              .to have_json_path("_embedded/attributesByTimestamp/1")
            expect(subject)
              .not_to have_json_path("_embedded/attributesByTimestamp/1/subject")
          end

          it "has a link to the work package at the timestamp" do
            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: [timestamps[0]]).to_json)
                    .at_path("_embedded/attributesByTimestamp/0/_links/self/href")
            expect(subject)
              .to be_json_eql(api_v3_paths.work_package(work_package.id, timestamps: [timestamps[1]]).to_json)
                    .at_path("_embedded/attributesByTimestamp/1/_links/self/href")
          end

          it "has no information about whether the work package matches the query filters at the timestamp " \
             "because there are no filters without a query" do
            expect(subject)
              .not_to have_json_path("_embedded/attributesByTimestamp/0/_meta/matchesFilters")
            expect(subject)
              .not_to have_json_path("_embedded/attributesByTimestamp/1/_meta/matchesFilters")
          end
        end

        describe "_meta" do
          describe "matchesFilters" do
            it "does not have this meta field without a query given" do
              expect(subject)
                .not_to have_json_path("_meta/matchesFilters")
            end
          end
        end

        context "when passing a query" do
          let(:search_term) { "original" }
          let(:query) do
            build(:query, user: current_user, project: nil).tap do |query|
              query.filters.clear
              query.add_filter "subject", "~", search_term
              query.timestamps = timestamps
            end
          end

          describe "attributesByTimestamp", with_ee: %i[baseline_comparison] do
            it "states whether the work package matches the query filters at the timestamp" do
              expect(subject)
                .to be_json_eql(true.to_json)
                      .at_path("_embedded/attributesByTimestamp/0/_meta/matchesFilters")
              expect(subject)
                .to be_json_eql(false.to_json)
                      .at_path("_embedded/attributesByTimestamp/1/_meta/matchesFilters")
            end
          end

          describe "_links" do
            it_behaves_like "has a titled link" do
              let(:link) { "self" }
              let(:href) { api_v3_paths.work_package(work_package.id, timestamps:) }
              let(:title) { work_package.name }
            end

            context "when changing timestamps it updates the link" do
              it_behaves_like "has a titled link" do
                before do
                  representer.to_json
                  representer.timestamps = []
                end

                let(:link) { "self" }
                let(:href) { api_v3_paths.work_package(work_package.id) }
                let(:title) { work_package.name }
              end
            end
          end

          describe "_meta" do
            describe "matchesFilters" do
              it "states whether the work package matches the query filters at the last timestamp" do
                # If this value is false, it means that the work package has been found by the query
                # at another of the given timestamps, e.g. the baseline timestamp.
                expect(subject)
                  .to be_json_eql(false.to_json)
                        .at_path("_meta/matchesFilters")
              end
            end
          end
        end
      end
    end

    describe "caching" do
      it "is based on the representer's cache_key" do
        allow(OpenProject::Cache)
          .to receive(:fetch)
                .and_return({ _links: {} }.to_json)

        allow(OpenProject::Cache)
          .to receive(:fetch)
                .with(representer.json_cache_key)
                .and_call_original

        representer.to_json

        expect(OpenProject::Cache)
          .to have_received(:fetch).with(representer.json_cache_key)
      end

      describe "#json_cache_key" do
        let(:category) { build_stubbed(:category) }
        let(:assigned_to) { build_stubbed(:user) }
        let(:responsible) { build_stubbed(:user) }

        before do
          work_package.category = category
          work_package.assigned_to = assigned_to
          work_package.responsible = responsible
        end

        it "includes the name of the representer class" do
          expect(representer.json_cache_key)
            .to include("API", "V3", "WorkPackages", "WorkPackageRepresenter")
        end

        it "changes when the locale changes" do
          expect(
            I18n.with_locale(:fr) { representer.json_cache_key }
          ).not_to eq(representer.json_cache_key)
        end

        it "changes when the feeds_enabled? setting is switched" do
          expect do
            allow(Setting)
              .to receive(:feeds_enabled?)
                    .and_return(!Setting.feeds_enabled?)
          end.to change(representer, :json_cache_key)
        end

        it "changes when the work_package_done_ratio setting is changes" do
          expect do
            allow(Setting)
              .to receive(:work_package_done_ratio)
                    .and_return("status")
          end.to change(representer, :json_cache_key)
        end

        it "changes when the work_package is updated" do
          expect do
            work_package.updated_at = 20.seconds.from_now
          end.to change(representer, :json_cache_key)
        end

        it "factors in the eager loaded cache_checksum" do
          without_partial_double_verification do
            allow(work_package)
              .to receive(:cache_checksum)
                    .and_return(srand)

            representer.json_cache_key

            expect(work_package)
              .to have_received(:cache_checksum)
          end
        end
      end
    end
  end

  describe "parsing" do
    describe "duration" do
      subject { representer }

      it "parses form iso8601 format" do
        subject.duration = "P6D"
        expect(subject.represented.duration).to eq(6)
      end
    end
  end
end
