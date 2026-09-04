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

RSpec.describe WorkPackages::BulkController, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:user) }
  shared_let(:custom_field2) { create(:work_package_custom_field) }
  shared_let(:user2) { create(:user) }
  shared_let(:custom_field_value) { "125" }
  shared_let(:custom_field1) do
    create(:work_package_custom_field,
           field_format: "string",
           is_for_all: true)
  end

  shared_let(:custom_field_user) { create(:issue_custom_field, :user) }
  shared_let(:status) { create(:status) }
  shared_let(:type) do
    create(:type_task,
           custom_fields: [custom_field1, custom_field2, custom_field_user])
  end
  shared_let(:project1) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field2])
  end
  shared_let(:project2) do
    create(:project,
           types: [type])
  end
  shared_let(:role) do
    create(:project_role,
           permissions: %i[edit_work_packages
                           delete_work_packages
                           view_work_packages
                           manage_subtasks
                           assign_versions
                           work_package_assigned])
  end
  shared_let(:member1_p1) do
    create(:member,
           project: project1,
           principal: user,
           roles: [role])
  end
  shared_let(:member2_p1) do
    create(:member,
           project: project1,
           principal: user2,
           roles: [role])
  end
  shared_let(:member1_p2) do
    create(:member,
           project: project2,
           principal: user,
           roles: [role])
  end
  shared_let(:work_package1, refind: true) do
    create(:work_package,
           author: user,
           assigned_to: user,
           responsible: user2,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project1)
  end
  shared_let(:work_package2, refind: true) do
    create(:work_package,
           author: user,
           assigned_to: user,
           responsible: user2,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project1)
  end
  shared_let(:work_package3, refind: true) do
    create(:work_package,
           author: user,
           type:,
           status:,
           custom_field_values: { custom_field1.id => custom_field_value },
           project: project2)
  end

  let(:stub_work_package) { build_stubbed(:work_package) }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe "#delete_dialog" do
    shared_let(:invisible_project) { create(:project, types: [type]) }
    shared_let(:invisible_work_package) { create(:work_package, type:, status:, project: invisible_project) }

    context "with a work package the user cannot see" do
      before do
        get :delete_dialog, params: { ids: [invisible_work_package.id] }, format: :turbo_stream
      end

      it "denies access" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a mix of visible and invisible work packages" do
      before do
        get :delete_dialog, params: { ids: [work_package1.id, invisible_work_package.id] }, format: :turbo_stream
      end

      it "denies access instead of offering to delete the visible subset" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with a visible work package" do
      before do
        get :delete_dialog, params: { ids: [work_package1.id] }, format: :turbo_stream
      end

      it "renders the dialog" do
        expect(response).to be_successful
      end
    end
  end

  describe "#edit" do
    shared_examples_for "response" do
      subject { response }

      it { is_expected.to be_successful }

      it { is_expected.to render_template("edit") }
    end

    context "within same project" do
      before { get :edit, params: { ids: [work_package1.id, work_package2.id] } }

      it_behaves_like "response"

      describe "#view" do
        render_views

        subject { response }

        describe "#parent" do
          it { assert_select "input", attributes: { name: "work_package[parent_id]" } }
        end

        context "with work package list" do
          context "with classic (numeric) identifiers" do
            it "displays a hash-prefixed numeric id link for each work package" do
              assert_select "ul li a", text: /\A#{Regexp.escape(work_package1.type.to_s)} ##{work_package1.id}\z/
              assert_select "ul li a", text: /\A#{Regexp.escape(work_package2.type.to_s)} ##{work_package2.id}\z/
            end
          end

          context "with semantic identifiers" do
            let(:semantic_prefix) { "TESTPROJ" }

            before do
              allow(Setting::WorkPackageIdentifier).to receive_messages(semantic?: true, classic?: false)
              work_package1.update_columns(identifier: "#{semantic_prefix}-1", sequence_number: 1)
              work_package2.update_columns(identifier: "#{semantic_prefix}-2", sequence_number: 2)
            end

            it "displays the semantic identifier in each link" do
              get :edit, params: { ids: [work_package1.id, work_package2.id] }

              assert_select "ul li a", text: /#{semantic_prefix}-1/
              assert_select "ul li a", text: /#{semantic_prefix}-2/
            end

            it "does not display a bare numeric id in the links" do
              get :edit, params: { ids: [work_package1.id, work_package2.id] }

              assert_select "ul li a", text: /##{work_package1.id}/, count: 0
              assert_select "ul li a", text: /##{work_package2.id}/, count: 0
            end
          end
        end

        context "custom_field" do
          describe "#type" do
            it { assert_select "input", attributes: { name: "work_package[custom_field_values][#{custom_field1.id}]" } }
          end

          describe "#project" do
            it { assert_select "select", attributes: { name: "work_package[custom_field_values][#{custom_field2.id}]" } }
          end

          describe "#user" do
            it { assert_select "select", attributes: { name: "work_package[custom_field_values][#{custom_field_user.id}]" } }
          end
        end
      end
    end

    context "with different projects" do
      before do
        member1_p2

        get :edit, params: { ids: [work_package1.id, work_package2.id, work_package3.id] }
      end

      it_behaves_like "response"

      describe "#view" do
        render_views

        subject { response }

        describe "#parent" do
          it { assert_select "input", { attributes: { name: "work_package[parent_id]" } }, false }
        end

        context "custom_field" do
          describe "#type" do
            it { assert_select "input", attributes: { name: "work_package[custom_field_values][#{custom_field1.id}]" } }
          end

          describe "#project" do
            it {
              assert_select "select", { attributes: { name: "work_package[custom_field_values][#{custom_field2.id}]" } }, false
            }
          end
        end
      end
    end
  end

  describe "#update" do
    let(:work_package_ids) { [work_package1.id, work_package2.id] }
    let(:work_packages) { WorkPackage.where(id: work_package_ids) }
    let(:priority) { create(:priority_immediate) }
    let(:group_id) { "" }
    let(:responsible_id) { "" }

    describe "#redirect" do
      context "in host" do
        let(:url) { "/work_packages" }

        before { put :update, params: { ids: work_package_ids, back_url: url } }

        subject { response }

        it { is_expected.to be_redirect }

        it { is_expected.to redirect_to(url) }
      end

      context "of host" do
        let(:url) { "http://google.com" }

        before { put :update, params: { ids: work_package_ids, back_url: url } }

        subject { response }

        it { is_expected.to be_redirect }

        it { is_expected.to redirect_to(project_work_packages_path(project1)) }
      end
    end

    shared_context "update_request" do
      before do
        put :update,
            params: {
              ids: work_package_ids,
              work_package: { priority_id: priority.id,
                              assigned_to_id: group_id,
                              responsible_id:,
                              send_notification:,
                              journal_notes: "Bulk editing" }
            }
      end
    end

    shared_examples_for "delivered" do
      subject { ActionMailer::Base.deliveries.size }

      it { delivery_size }
    end

    context "with notification" do
      let(:send_notification) { "1" }
      let(:delivery_size) { 2 }

      shared_examples_for "updated work package" do
        describe "#priority" do
          subject { WorkPackage.where(priority_id: priority.id).map(&:id) }

          it { is_expected.to match_array(work_package_ids) }
        end

        describe "#custom_fields" do
          let(:result) { [custom_field_value] }

          subject do
            WorkPackage.where(id: work_package_ids)
              .map { |w| w.custom_value_for(custom_field1).value }
              .uniq
          end

          it { is_expected.to match_array(result) }
        end

        describe "#journal" do
          describe "#notes" do
            let(:result) { ["Bulk editing"] }

            subject do
              WorkPackage.where(id: work_package_ids)
                .map { |w| w.last_journal.notes }
                .uniq
            end

            it { is_expected.to match_array(result) }
          end

          describe "#details" do
            let(:result) { [1] }

            subject do
              WorkPackage.where(id: work_package_ids)
                .map { |w| w.last_journal.details.size }
                .uniq
            end

            it { is_expected.to match_array(result) }
          end
        end
      end

      context "with a single project" do
        include_context "update_request"

        it { expect(response.response_code).to eq(302) }

        it_behaves_like "delivered"

        it_behaves_like "updated work package"
      end

      context "with different projects" do
        let(:work_package_ids) { [work_package1.id, work_package2.id, work_package3.id] }

        context "with permission" do
          include_context "update_request"

          it { expect(response.response_code).to eq(302) }

          it_behaves_like "delivered"

          it_behaves_like "updated work package"
        end

        context "without permission" do
          include_context "update_request"

          before_all do
            member1_p2.destroy
          end

          it { expect(response.response_code).to eq(403) }

          describe "#journal" do
            subject { Journal.for_work_package.count }

            it { is_expected.to eq(work_package_ids.count) }
          end
        end
      end

      describe "#properties" do
        describe "#groups" do
          let(:group) { create(:group) }
          let(:group_id) { group.id }

          subject { work_packages.map(&:assigned_to_id).uniq }

          context "when allowed" do
            let!(:member_group_p1) do
              create(:member,
                     project: project1,
                     principal: group,
                     roles: [role])
            end

            include_context "update_request"
            it "does succeed" do
              expect(flash[:error]).to be_nil
              expect(subject).to contain_exactly(group.id)
            end
          end

          context "when not allowed" do
            render_views

            include_context "update_request"

            it "does not succeed" do
              expect(flash[:error])
                .to include(I18n.t(:"work_packages.bulk.none_could_be_saved",
                                   total: 2))
              expect(subject).to contain_exactly(user.id)
            end
          end
        end

        describe "#responsible" do
          let(:responsible_id) { user.id }

          include_context "update_request"

          subject { work_packages.map(&:responsible_id).uniq }

          it { is_expected.to contain_exactly(responsible_id) }
        end

        describe "#status" do
          let(:closed_status) { create(:closed_status) }
          let(:workflow) do
            create(:workflow,
                   role:,
                   type_id: type.id,
                   old_status: status,
                   new_status: closed_status)
          end

          before do
            workflow

            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { status_id: closed_status.id }
                }
          end

          subject { work_packages.map(&:status_id).uniq }

          it { is_expected.to contain_exactly(closed_status.id) }
        end

        describe "#parent" do
          let(:parent) do
            create(:work_package,
                   author: user,
                   project: project1)
          end

          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { parent_id: parent.id }
                }
          end

          subject { work_packages.map(&:parent_id).uniq }

          it { is_expected.to contain_exactly(parent.id) }
        end

        describe "#custom_fields" do
          let(:result) { "777" }

          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: {
                    custom_field_values: { custom_field1.id.to_s => result }
                  }
                }
          end

          subject do
            work_packages.map { |w| w.custom_value_for(custom_field1).value }
                         .uniq
          end

          it { is_expected.to contain_exactly(result) }
        end

        describe "#unassign" do
          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { assigned_to_id: "none" }
                }
          end

          subject { work_packages.map(&:assigned_to_id).uniq }

          it { is_expected.to contain_exactly(nil) }
        end

        describe "#delete_responsible" do
          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { responsible_id: "none" }
                }
          end

          subject { work_packages.map(&:responsible_id).uniq }

          it { is_expected.to contain_exactly(nil) }
        end

        describe "#version" do
          describe "set target_version_ids attribute",
                   with_settings: { work_package_multiple_versions: true } do
            shared_let(:target_subproject) do
              create(:project, parent: project1, types: [type])
            end
            shared_let(:target_version) do
              create(:version, status: "open", sharing: "tree", project: target_subproject)
            end

            describe "to a version" do
              before do
                put :update,
                    params: {
                      ids: work_package_ids,
                      work_package: { target_version_ids: [target_version.id.to_s] }
                    }
              end

              it "redirects on success" do
                expect(response).to be_redirect
              end

              it "assigns the version as target_versions on every selected work package" do
                expect(work_packages.map { |wp| wp.target_versions.pluck(:id) }.uniq)
                  .to contain_exactly([target_version.id])
              end

              it "does not move the work packages into the version's project" do
                expect(work_packages.map(&:project_id).uniq)
                  .not_to contain_exactly(target_subproject.id)
              end
            end

            describe "to none" do
              before do
                work_packages.each do |wp|
                  wp.work_package_versions.create!(version_id: target_version.id, kind: "target")
                end

                # 'none' is a magic value that clears all target_versions
                put :update,
                    params: {
                      ids: work_package_ids,
                      work_package: { target_version_ids: ["none"] }
                    }
              end

              it "clears the target_versions on every selected work package" do
                expect(work_packages.map { |wp| wp.target_versions.pluck(:id) }.uniq)
                  .to contain_exactly([])
              end
            end
          end

          describe "set observed_in_version_ids attribute" do
            shared_let(:observed_in_subproject) do
              create(:project, parent: project1, types: [type])
            end
            shared_let(:observed_in_version) do
              create(:version, status: "open", sharing: "tree", project: observed_in_subproject)
            end

            describe "to a version" do
              before do
                put :update,
                    params: {
                      ids: work_package_ids,
                      work_package: { observed_in_version_ids: [observed_in_version.id.to_s] }
                    }
              end

              it "redirects on success" do
                expect(response).to be_redirect
              end

              it "assigns the version as observed_in_versions on every selected work package" do
                expect(work_packages.map { |wp| wp.observed_in_versions.pluck(:id) }.uniq)
                  .to contain_exactly([observed_in_version.id])
              end

              it "does not move the work packages into the version's project" do
                expect(work_packages.map(&:project_id).uniq)
                  .not_to contain_exactly(observed_in_subproject.id)
              end
            end

            describe "to none" do
              before do
                work_packages.each do |wp|
                  wp.work_package_versions.create!(version_id: observed_in_version.id, kind: "observed_in")
                end

                # 'none' is a magic value that clears all observed_in_versions
                put :update,
                    params: {
                      ids: work_package_ids,
                      work_package: { observed_in_version_ids: ["none"] }
                    }
              end

              it "clears the observed_in_versions on every selected work package" do
                expect(work_packages.map { |wp| wp.observed_in_versions.pluck(:id) }.uniq)
                  .to contain_exactly([])
              end
            end
          end
        end

        describe "#done_ratio" do
          before do
            put :update,
                params: {
                  ids: work_package_ids,
                  work_package: { done_ratio: }
                }
          end

          context "with a valid done_ratio" do
            let(:done_ratio) { 55 }

            subject { work_packages.map(&:done_ratio).uniq }

            it { is_expected.to contain_exactly(55) }
          end

          context "with an invalid done_ratio" do
            let(:done_ratio) { 150 }

            subject { work_packages.map(&:done_ratio).uniq }

            it "does not succeed" do
              expect(flash[:error])
                .to include(I18n.t(:"work_packages.bulk.none_could_be_saved",
                                   total: 2))

              expect(subject).to contain_exactly(nil)
            end
          end
        end
      end
    end

    context "without notification" do
      let(:send_notification) { "0" }

      describe "#delivery" do
        include_context "update_request"

        let(:delivery_size) { 0 }

        it { expect(response.response_code).to eq(302) }

        it_behaves_like "delivered"
      end
    end

    context "with semantic identifiers",
            with_settings: { work_packages_identifier: "semantic" } do
      before do
        work_package1.update_columns(identifier: "PROJ-1", sequence_number: 1)
        work_package2.update_columns(identifier: "PROJ-2", sequence_number: 2)
        put :update,
            params: {
              ids: work_package_ids,
              work_package: { done_ratio: 150 }
            }
      end

      it "shows semantic identifiers in the error flash" do
        expect(flash[:error]).to include("PROJ-1")
        expect(flash[:error]).to include("PROJ-2")
      end

      it "does not show bare numeric ids in the error flash" do
        expect(flash[:error]).not_to include("##{work_package1.id}")
        expect(flash[:error]).not_to include("##{work_package2.id}")
      end
    end

    describe "updating two children with dates to a new parent (Regression #28670)" do
      let(:task1) do
        create(:work_package,
               project: project1,
               start_date: 5.days.ago,
               due_date: Date.current)
      end

      let(:task2) do
        create(:work_package,
               project: project1,
               start_date: 2.days.ago,
               due_date: 1.day.from_now)
      end

      let(:new_parent) do
        create(:work_package, schedule_manually: false, project: project1)
      end

      before do
        put :update,
            params: {
              ids: [task1.id, task2.id],
              notes: "Bulk editing",
              work_package: { parent_id: new_parent.id }
            }
      end

      it "updates the parent dates as well" do
        expect(response.response_code).to eq(302)

        task1.reload
        task2.reload
        new_parent.reload

        expect(task1.parent_id).to eq(new_parent.id)
        expect(task2.parent_id).to eq(new_parent.id)

        expect(new_parent.start_date).to eq(task1.start_date)
        expect(new_parent.due_date).to eq(task2.due_date)
      end
    end

    describe "bulk parent assignment with semantic identifiers",
             with_settings: { work_packages_identifier: "semantic" } do
      let(:sem_project) do
        create(:project, identifier: "SEMPROJ", types: [type]).tap do |p|
          create(:member, project: p, principal: user, roles: [role])
        end
      end
      let(:parent_wp) { create(:work_package, project: sem_project).reload }
      let(:child1)    { create(:work_package, project: sem_project).reload }
      let(:child2)    { create(:work_package, project: sem_project).reload }

      it "accepts a semantic identifier and assigns the parent" do
        put :update,
            params: {
              ids: [child1.id, child2.id],
              work_package: { parent_id: parent_wp.identifier }
            }

        expect(response).to have_http_status(:found)
        expect(child1.reload.parent_id).to eq(parent_wp.id)
        expect(child2.reload.parent_id).to eq(parent_wp.id)
      end

      it "reports an error for an unknown semantic identifier" do
        put :update,
            params: {
              ids: [child1.id, child2.id],
              work_package: { parent_id: "SEMPROJ-9999" }
            }

        expect(flash[:error]).to be_present
        expect(child1.reload.parent_id).to be_nil
        expect(child2.reload.parent_id).to be_nil
      end
    end
  end

  describe "#destroy" do
    def send_destroy_request
      as_logged_in_user(user) do
        delete :destroy, params:
      end
    end

    describe "with the cleanup being successful" do
      let(:params) { { "ids" => [work_package1.id, work_package2.id] } }

      it "deletes the work packages and redirects to the project" do
        send_destroy_request
        expect(WorkPackage.find_by(id: [work_package1.id, work_package2.id])).to be_nil
        expect(response).to redirect_to(project_work_packages_path(work_package1.project))
      end

      it "reports how many were deleted" do
        send_destroy_request

        expect(flash[:notice]).to eq(I18n.t("work_packages.bulk.deletion_successful", count: 2))
      end
    end

    context "with a selected work package that has descendants" do
      shared_let(:child) { create(:work_package, type:, status:, project: project1, parent: work_package1) }
      shared_let(:grandchild) { create(:work_package, type:, status:, project: project1, parent: child) }

      let(:params) { { "ids" => [work_package1.id] } }

      it "counts the descendants it deleted along the way" do
        send_destroy_request

        expect(flash[:notice]).to eq(I18n.t("work_packages.bulk.deletion_successful", count: 3))
      end
    end

    context "with an ancestor that is only rescheduled" do
      shared_let(:parent) do
        create(:work_package, type:, status:, project: project1, schedule_manually: false)
      end
      shared_let(:child) do
        create(:work_package, type:, status:, project: project1, parent:,
                              start_date: Date.parse("2026-01-05"), due_date: Date.parse("2026-01-09"))
      end
      shared_let(:sibling) do
        create(:work_package, type:, status:, project: project1, parent:,
                              start_date: Date.parse("2026-02-02"), due_date: Date.parse("2026-02-06"))
      end

      let(:params) { { "ids" => [child.id] } }

      it "does not count the ancestor as deleted" do
        send_destroy_request

        expect(flash[:notice]).to eq(I18n.t("work_packages.bulk.deletion_successful", count: 1))
      end
    end

    describe "with the cleanup being unsuccessful" do
      let(:params) { { "ids" => [work_package1.id, work_package2.id], "to_do" => "blubs" } }

      before do
        allow(WorkPackage).to receive(:cleanup_associated_before_destructing_if_required)
                                .with([work_package1, work_package2], user, params["to_do"])
                                .and_return false
      end

      it "does not delete the work packages and redirects to the reassign action" do
        send_destroy_request
        expect(WorkPackage.find_by(id: work_package1.id)).to be_present
        expect(WorkPackage.find_by(id: work_package2.id)).to be_present
        expect(response).to redirect_to(
          reassign_work_packages_bulk_path(ids: [work_package1.id, work_package2.id], delete_descendants: true)
        )
      end
    end

    context "with work packages being related (parent, child, and successor)" do
      let(:params) { { "ids" => [work_package1.id, work_package2.id, work_package3.id] } }

      before do
        work_package1.update(subject: "wp", schedule_manually: false)
        work_package2.update(subject: "child of wp", parent: work_package1)
        work_package3.update(subject: "successor of wp")
        create(:follows_relation, predecessor: work_package1, successor: work_package3)
      end

      it "deletes them all without errors" do
        send_destroy_request
        expect(WorkPackage.count).to eq(0)
        expect(response).to redirect_to(project_work_packages_path(work_package1.project))
      end
    end

    context "with a child in a project the user has no access to" do
      shared_let(:foreign_project) { create(:project, types: [type]) }
      shared_let(:foreign_child) do
        create(:work_package, type:, status:, project: foreign_project, parent: work_package1)
      end

      let(:params) { { "ids" => [work_package1.id] } }

      it "deletes the work package and detaches the child" do
        send_destroy_request

        expect(WorkPackage).not_to exist(work_package1.id)
        expect(foreign_child.reload.parent_id).to be_nil
        expect(flash[:error]).to be_nil
      end
    end

    context "with children work packages following each other" do
      before_all do
        work_package1.update(subject: "parent", schedule_manually: false)
        work_package2.update(subject: "predecessor child", parent: work_package1, schedule_manually: true)
        work_package3.update(subject: "successor child", parent: work_package1, schedule_manually: false)
        create(:follows_relation, predecessor: work_package2, successor: work_package3)
      end

      let(:params) { { "ids" => [work_package1.id, work_package2.id, work_package3.id] } }

      it "deletes them all without errors" do
        expect { send_destroy_request }.not_to raise_error

        expect(WorkPackage.count).to eq(0)
        expect(response).to redirect_to(project_work_packages_path(project1))
      end
    end
  end

  describe "the descendants deletion choice" do
    let(:parent_wp) { create(:work_package, author: user, type:, status:, project: project1) }
    let!(:child_wp) do
      create(:work_package, author: user, type:, status:, project: project1, parent: parent_wp)
    end

    describe "#delete_dialog" do
      it "offers two choices when the selection has descendants" do
        as_logged_in_user(user) do
          get :delete_dialog, params: { ids: [parent_wp.id] }, format: :turbo_stream
        end

        expect(response.body).to include("delete_descendants")
        expect(response.body).to include(I18n.t("work_packages.delete_dialog.descendants_choice.self_only_label"))
      end
    end

    describe "#confirm_delete" do
      it "opens the confirmation dialog without deleting anything when cascading" do
        as_logged_in_user(user) do
          post :confirm_delete, params: { ids: [parent_wp.id], delete_descendants: true }, format: :turbo_stream
        end

        expect(response).to be_successful
        expect(response.body).to include(WorkPackages::DeleteDescendantsDialogComponent::DIALOG_ID)
        expect(WorkPackage).to exist(parent_wp.id)
        expect(child_wp.reload.parent_id).to eq(parent_wp.id)
      end

      it "deletes only the roots and detaches the descendants when keeping them" do
        as_logged_in_user(user) do
          post :confirm_delete, params: { ids: [parent_wp.id], delete_descendants: false }
        end

        expect(WorkPackage).not_to exist(parent_wp.id)
        expect(WorkPackage).to exist(child_wp.id)
        expect(child_wp.reload.parent_id).to be_nil
      end
    end

    describe "#destroy with the keep-descendants choice" do
      it "detaches a deletable descendant instead of deleting it" do
        as_logged_in_user(user) do
          delete :destroy, params: { ids: [parent_wp.id], delete_descendants: false }
        end

        expect(WorkPackage).not_to exist(parent_wp.id)
        expect(WorkPackage).to exist(child_wp.id)
        expect(child_wp.reload.parent_id).to be_nil
      end

      it "carries the choice through the reassign redirect when cleanup is required" do
        allow(WorkPackage)
          .to receive(:cleanup_associated_before_destructing_if_required)
          .and_return false

        as_logged_in_user(user) do
          delete :destroy, params: { ids: [parent_wp.id], to_do: "blubs", delete_descendants: false }
        end

        expect(response).to redirect_to(
          reassign_work_packages_bulk_path(ids: [parent_wp.id], delete_descendants: false)
        )
      end
    end

    describe "#reassign" do
      render_views

      it "renders the form and carries the descendants choice through a hidden field" do
        as_logged_in_user(user) do
          get :reassign, params: { ids: [parent_wp.id], delete_descendants: "false" }
        end

        expect(response).to be_successful
        expect(response.body).to include('name="delete_descendants"')
      end
    end
  end
end
