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

RSpec.describe WorkPackages::MovesController, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:user) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i(move_work_packages
                           copy_work_packages
                           view_work_packages
                           add_work_packages
                           edit_work_packages
                           assign_versions
                           manage_subtasks
                           work_package_assigned))
  end
  shared_let(:type) { create(:type) }
  shared_let(:type2) { create(:type) }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:priority) }
  shared_let(:target_priority) { create(:priority) }
  shared_let(:project) do
    create(:project,
           public: false,
           types: [type, type2])
  end
  shared_let(:work_package) do
    create(:work_package,
           project_id: project.id,
           type:,
           author: user,
           priority:)
  end

  shared_let(:current_user) { create(:user) }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe "new.html" do
    become_admin

    describe "without a valid planning element id" do
      describe "without being a member or administrator" do
        become_non_member

        it "renders a 404 page" do
          get "new", params: { id: "1337" }

          expect(response.response_code).to be === 404
        end
      end

      describe "with the current user being a member" do
        become_member_with_view_planning_element_permissions

        it "raises ActiveRecord::RecordNotFound errors" do
          get "new", params: { id: "1337" }

          expect(response.response_code).to be === 404
        end
      end
    end

    describe "with a valid planning element id" do
      become_admin

      describe "without being a member or administrator" do
        become_non_member

        it "renders a 403 Forbidden page" do
          get "new", params: { work_package_id: work_package.id }

          expect(response.response_code).to eq(403)
        end
      end

      describe "with the current user being a member" do
        become_member_with_move_work_package_permissions

        before do
          get "new", params: { work_package_id: work_package.id }
        end

        it "renders the new builder template" do
          expect(response).to render_template("work_packages/moves/new")
        end
      end

      describe "with a semantic work package identifier",
               with_settings: { work_packages_identifier: "semantic" } do
        let(:semantic_project) { create(:project, :semantic, public: false, types: [type, type2]) }
        let(:semantic_target_project) { create(:project, :semantic, public: false, types: [type, type2]) }
        let(:semantic_work_package) do
          create(:work_package, project: semantic_project, type:, author: user, priority:)
        end
        let!(:semantic_member) { create(:member, user: current_user, project: semantic_project, roles: [role]) }
        let!(:semantic_target_member) { create(:member, user: current_user, project: semantic_target_project, roles: [role]) }

        it "resolves the semantic identifier and renders the new builder template" do
          get "new", params: { work_package_id: semantic_work_package.display_id }

          expect(response).to render_template("work_packages/moves/new")
        end

        it "resolves the semantic identifier on create and moves the work package" do
          post :create, params: {
            work_package_id: semantic_work_package.display_id,
            new_project_id: semantic_target_project.id,
            new_type_id: semantic_target_project.types.first.id,
            follow: "1"
          }

          expect(response).to be_redirect
          expect(semantic_work_package.reload.project_id).to eq(semantic_target_project.id)
          expect(response.location).to match(%r{/work_packages/#{semantic_target_project.identifier}-\d+})
        end
      end
    end
  end

  describe "#create" do
    context "when the user has copy_work_packages but not move_work_packages" do
      let(:copy_only_role) do
        create(:project_role,
               permissions: %i[copy_work_packages view_work_packages edit_work_packages])
      end
      let!(:source_member) { create(:member, user: current_user, project:, roles: [copy_only_role]) }

      it "renders a 403 Forbidden page" do
        post :create,
             params: {
               work_package_id: work_package.id
             }

        expect(response.response_code).to eq(403)
      end
    end

    let!(:source_member) { create(:member, user: current_user, project:, roles: [role]) }
    let!(:target_member) { create(:member, user: current_user, project: target_project, roles: [role]) }
    let(:target_project) { create(:project, public: false) }
    let(:work_package_2) do
      create(:work_package,
             project_id: project.id,
             type: type2,
             priority:)
    end

    describe "an issue to another project" do
      context "without following" do
        before do
          status
        end

        subject do
          post :create,
               params: {
                 work_package_id: work_package.id,
                 new_project_id: target_project.id,
                 type_id: "",
                 author_id: user.id,
                 assigned_to_id: "",
                 responsible_id: "",
                 status_id: "",
                 start_date: "",
                 due_date: ""
               }
        end

        it "redirects to the project's work packages page" do
          expect(subject).to be_redirect
          expect(subject).to redirect_to(project_work_packages_path(project))
        end
      end

      context "with following" do
        subject do
          post :create,
               params: {
                 work_package_id: work_package.id,
                 new_project_id: target_project.id,
                 new_type_id: target_project.types.first.id,
                 assigned_to_id: "",
                 responsible_id: "",
                 status_id: "",
                 start_date: "",
                 due_date: "",
                 follow: "1"
               }
        end

        it "redirects to the work package page" do
          expect(subject).to be_redirect
          expect(subject).to redirect_to(work_package_path(work_package))
        end
      end
    end

    describe "bulk move" do
      context "with two work packages" do
        before do
          # make sure, that the types of the work-packages are available on the target-project
          # (and handle it/test it, when this is not the case see #1868)
          target_project.types << [work_package.type, work_package_2.type]
          target_project.save

          post :create,
               params: {
                 ids: [work_package.id, work_package_2.id],
                 new_project_id: target_project.id
               }
        end

        it "project id is changed for both work packages, but keeps types" do
          work_package.reload
          work_package_2.reload

          expect(work_package.project_id).to eq(target_project.id)
          expect(work_package_2.project_id).to eq(target_project.id)

          expect(work_package.type_id).to eq(type.id)
          expect(work_package_2.type_id).to eq(type2.id)
        end

        context "when the limit to move in the frontend is 1",
                with_settings: { work_packages_bulk_request_limit: 1 } do
          it "only schedules the move job" do
            expect(WorkPackages::BulkMoveJob)
              .to have_been_enqueued

            work_package.reload
            work_package_2.reload

            expect(work_package.project_id).to eq(project.id)
            expect(work_package_2.project_id).to eq(project.id)

            perform_enqueued_jobs

            work_package.reload
            work_package_2.reload

            expect(work_package.project_id).to eq(target_project.id)
            expect(work_package_2.project_id).to eq(target_project.id)
            expect(work_package.type_id).to eq(type.id)
            expect(work_package_2.type_id).to eq(type2.id)
          end
        end
      end

      context "to another type" do
        before do
          post :create,
               params: {
                 ids: [work_package.id, work_package_2.id],
                 new_type_id: type2.id
               }
          work_package.reload
          work_package_2.reload
        end

        it "changed work packages' types" do
          expect(work_package.type_id).to eq(type2.id)
          expect(work_package_2.type_id).to eq(type2.id)
        end
      end

      context "with another priority" do
        before do
          post :create,
               params: {
                 ids: [work_package.id, work_package_2.id],
                 priority_id: target_priority.id
               }
          work_package.reload
          work_package_2.reload
        end

        it "changed work packages' priority" do
          expect(work_package.priority_id).to eq(target_priority.id)
          expect(work_package_2.priority_id).to eq(target_priority.id)
        end
      end

      shared_examples_for "single note for moved work package" do
        it { expect(moved_work_package.journals.count).to eq(2) }

        it { expect(moved_work_package.journals.max_by(&:id).notes).to eq(note) }
      end

      describe "move with given note" do
        let(:note) { "Moving a work package" }

        context "without work package changes" do
          before do
            post :create,
                 params: {
                   ids: [work_package.id],
                   notes: note
                 }
          end

          it_behaves_like "single note for moved work package" do
            let(:moved_work_package) { work_package.reload }
          end
        end

        context "with a work package priority change" do
          before do
            post :create,
                 params: {
                   ids: [work_package.id],
                   notes: note,
                   priority_id: target_priority.id
                 }
          end

          it_behaves_like "single note for moved work package" do
            let(:moved_work_package) { work_package.reload }
          end
        end
      end

      describe "& duplicate" do
        context "when following to another project" do
          before do
            post :create,
                 params: {
                   ids: [work_package.id],
                   copy: "",
                   new_project_id: target_project.id,
                   new_type_id: target_project.types.first.id, # FIXME see #1868
                   follow: ""
                 }
          end

          it "redirects to the work package copy" do
            copy = WorkPackage.order(id: :desc).first
            expect(subject).to redirect_to(work_package_path(copy))
          end
        end

        context "without changing the work package's attribute" do
          before do
            post :create,
                 params: {
                   ids: [work_package.id],
                   copy: "",
                   new_project_id: target_project.id
                 }
          end

          subject { WorkPackage.order(Arel.sql("id desc")).where(project_id: project.id).first }

          it "did not change the type" do
            expect(subject.type_id).to eq(work_package.type_id)
          end

          it "did not change the status" do
            expect(subject.status_id).to eq(work_package.status_id)
          end

          it "did not change the version" do
            expect(subject.version_id).to eq(work_package.version_id)
          end

          it "did not change the assignee" do
            expect(subject.assigned_to_id).to eq(work_package.assigned_to_id)
          end

          it "did not change the responsible" do
            expect(subject.responsible_id).to eq(work_package.responsible_id)
          end
        end

        context "with changing the work package's attribute" do
          let(:start_date) { Date.current }
          let(:due_date) { Date.tomorrow }
          let(:target_version) { create(:version, project: target_project) }
          let(:target_type) { target_project.types.first }
          let(:target_status) { create(:status, workflow_for_type: target_type) }

          let(:target_user) do
            user = create(:user)

            create(:member,
                   user:,
                   project: target_project,
                   roles: [role])

            user
          end

          before do
            post :create,
                 params: {
                   ids: [work_package.id, work_package_2.id],
                   copy: "",
                   new_project_id: target_project.id,
                   new_type_id: target_type.id, # FIXME see #1868
                   assigned_to_id: target_user.id,
                   responsible_id: target_user.id,
                   status_id: target_status,
                   version_id: target_version.id,
                   start_date:,
                   due_date:
                 }
          end

          subject { WorkPackage.limit(2).order(Arel.sql("id desc")).where(project_id: target_project.id) }

          it "duplicates two work packages" do
            expect(subject.count).to eq(2)
          end

          it "did change the project" do
            subject.map(&:project_id).each do |id|
              expect(id).to eq(target_project.id)
            end
          end

          it "did change the assignee" do
            subject.map(&:assigned_to_id).each do |id|
              expect(id).to eq(target_user.id)
            end
          end

          it "did change the responsible" do
            subject.map(&:responsible_id).each do |id|
              expect(id).to eq(target_user.id)
            end
          end

          it "did change the status" do
            subject.map(&:status_id).each do |id|
              expect(id).to eq(target_status.id)
            end
          end

          it "did change the version" do
            subject.map(&:version_id).each do |id|
              expect(id).to eq(target_version.id)
            end
          end

          it "did change the start date" do
            subject.map(&:start_date).each do |date|
              expect(date).to eq(start_date)
            end
          end

          it "did change the end date" do
            subject.map(&:due_date).each do |date|
              expect(date).to eq(due_date)
            end
          end
        end

        context "with given note" do
          let(:note) { "Duplicating a work package" }

          before do
            post :create,
                 params: {
                   ids: [work_package.id],
                   copy: "",
                   notes: note
                 }
          end

          subject { WorkPackage.limit(1).order(Arel.sql("id desc")).last.journals }

          it "contains that note" do
            expect(subject.count).to eq(1)
            expect(subject.last.notes).to eq(note)
          end
        end

        context "parent and child work package" do
          let!(:child_wp) do
            create(:work_package,
                   type:,
                   project:,
                   parent: work_package)
          end

          before do
            allow(User).to receive(:current).and_return(current_user)
          end

          context "on new" do
            render_views

            before do
              get :new,
                  params: {
                    ids: [work_package.id, child_wp.id],
                    copy: "",
                    new_project_id: target_project.id
                  }
            end

            it "reports the one child work package" do
              expect(response.body).to have_css "a.work_package", count: 2
              expect(response.body).to have_css ".contextual-info", text: "(+ One descendant work package)"
            end
          end

          context "when duplicating the parent with a child exceeds the request limit",
                  with_settings: { work_packages_bulk_request_limit: 1 } do
            let(:note) { "Duplicating a work package" }

            before do
              post :create,
                   params: {
                     ids: [work_package.id],
                     copy: "",
                     notes: note
                   }
            end

            subject { WorkPackage.limit(2).order(Arel.sql("id desc")).last.journals }

            it "runs in the background" do
              expect(WorkPackages::BulkCopyJob)
                .to have_been_enqueued

              expect { perform_enqueued_jobs }
                .to change(WorkPackage, :count)
                .by(2)

              expect(subject.first.notes).to eq(note)
              expect(subject.last.notes).to eq(note)
            end
          end
        end

        context "when duplicating child work package from one project to other" do
          let(:to_project) do
            create(:project,
                   types: [type])
          end
          let!(:member) do
            create(:member,
                   user: current_user,
                   roles: [role],
                   project: to_project)
          end
          let!(:child_wp) do
            create(:work_package,
                   type:,
                   project:,
                   parent: work_package)
          end

          shared_examples_for "successful move" do
            it { expect(flash[:notice]).to eq(I18n.t(:notice_successful_create)) }
          end

          before do
            allow(User).to receive(:current).and_return(current_user)

            def self.copy_child_work_package
              post :create,
                   params: {
                     ids: [child_wp.id],
                     copy: "",
                     new_project_id: to_project.id,
                     work_package_id: child_wp.id,
                     new_type_id: to_project.types.first.id
                   }
            end
          end

          context "when cross_project_work_package_relations is disabled" do
            render_views

            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(false)

              copy_child_work_package
            end

            it "is unsuccessful" do
              expect(flash[:error])
                .to include(I18n.t(:"work_packages.bulk.none_could_be_saved",
                                   total: 1))
            end
          end

          context "when cross_project_work_package_relations is enabled" do
            before do
              allow(Setting).to receive(:cross_project_work_package_relations?).and_return(true)

              copy_child_work_package
            end

            it_behaves_like "successful move"

            it { expect(to_project.work_packages.first.parent).to eq(child_wp.parent) }
          end
        end
      end
    end
  end
end
