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

require "rails_helper"

RSpec.describe Backlogs::WorkPackagesController do
  delegate :body, to: :response

  # Gets the html content of the template of the first turbo-stream with the
  # given action.
  def turbo_stream_template(action:)
    assert_select("turbo-stream[action=#{action}] template").first.inner_html
  end

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }

  current_user { user }

  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project, types: [type_feature, type_task]) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }

  let(:sprint) { create(:sprint, name: "Agile Sprint 1", project:) }
  let(:work_package) { create(:work_package, status:, sprint:, project:, type: type_feature) }

  shared_examples "shows a flash message after moving a work package that turns invisible" do |target_name|
    it "shows a flash message after moving the work package" do
      message = "The work package was moved to #{target_name} but is not visible"
      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
      expect(turbo_stream_template(action: "flash")).to include(message)
      expect(response).not_to have_turbo_stream action: "liveRegion"
    end
  end

  describe "load_work_package" do
    let(:params) { { project_id: project.id, id: work_package.id } }

    subject(:response) { get :menu, params:, format: :html }

    it "assigns the visible work package", :aggregate_failures do
      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(assigns(:work_package)).to eq(work_package)
    end

    context "when the work package is not in the requested project" do
      let(:requested_project) { create(:project) }
      let(:params) { { project_id: requested_project.id, id: work_package.id } }

      it { is_expected.to have_http_status :not_found }
    end
  end

  describe "PUT #move" do
    let(:work_package_in_sprint) { create(:work_package, status:, sprint:, project:) }
    let(:project_id) { project.id }
    let(:id) { work_package_in_sprint.id }
    let(:list_type) { nil }
    let(:list_id) { nil }
    let(:prev_id) { nil }
    let(:position) { nil }
    let(:all) { nil }
    # The move URL carries the page's active backlog filters (see move_path).
    let(:filter_params) { {} }
    let(:optimistic) { nil }

    subject(:response) do
      put :move, params: { project_id:, id:, list_type:, list_id:, prev_id:, position:, all:, optimistic:,
                           **filter_params },
                 format: :turbo_stream
    end

    context "with a Sprint as source" do
      context "with the same Sprint as target" do
        let(:list_type) { "sprint" }
        let(:list_id) { sprint.id }

        it "replaces the sprint component once and emits no flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
        end

        it "does not change the work_package's sprint and position" do
          expect do
            response

            sprint.reload
          end.not_to change(sprint, :attributes)
        end
      end

      context "with another Sprint as target" do
        let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
        let(:list_type) { "sprint" }
        let(:list_id) { other_sprint.id }

        it "responds with success and moves work_package to another Sprint", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:work_package)).to eq(work_package_in_sprint)
        end

        it "moves the work_package to the target sprint" do
          response

          expect(work_package_in_sprint.reload).to have_attributes(sprint: other_sprint, backlog_bucket_id: nil, position: 1)
        end

        context "when the active sprint filter hides the target sprint" do
          let(:filter_params) { { sprint_ids: [sprint.id] } }

          include_examples "shows a flash message after moving a work package that turns invisible", "Agile Sprint 2"
        end

        context "when the active sprint filter includes the target sprint" do
          let(:filter_params) { { sprint_ids: [sprint.id, other_sprint.id] } }

          it "emits no flash", :aggregate_failures do
            expect(response).to be_successful
            expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
          end
        end
      end

      context "with a blank prev_id (move to the top of the target list)" do
        let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
        let!(:existing_target_items) { create_list(:work_package, 2, project:, status:, sprint: other_sprint) }
        let(:list_type) { "sprint" }
        let(:list_id) { other_sprint.id }
        let(:prev_id) { "" }

        it "moves the work_package to the first position" do
          subject

          expect(work_package_in_sprint.reload).to have_attributes(sprint: other_sprint, position: 1)
        end
      end

      context "with Inbox as target" do
        let!(:existing_inbox_item) { create(:work_package, project:, status:, position: 1) }
        let(:list_type) { "inbox" }
        let(:prev_id) { existing_inbox_item.id }

        it "replaces the sprints and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:work_package)).to eq(work_package_in_sprint)
        end

        context "when the project is configured to exclude the work packages status from backlogs" do
          before do
            project.done_statuses << status
          end

          include_examples "shows a flash message after moving a work package that turns invisible", "Inbox"
        end

        context "when the project is configured to exclude the work packages type from backlogs" do
          before do
            project.backlog_excluded_types << type_feature
          end

          include_examples "shows a flash message after moving a work package that turns invisible", "Inbox"
        end

        context "when the active bucket filter hides the inbox" do
          let(:bucket) { create(:backlog_bucket, project:) }
          let(:filter_params) { { bucket_ids: [bucket.id] } }

          include_examples "shows a flash message after moving a work package that turns invisible", "Inbox"
        end

        it "moves the work_package to the inbox at the given position" do
          response

          expect(work_package_in_sprint.reload).to have_attributes(sprint_id: nil, backlog_bucket_id: nil, position: 2)
        end

        context "with a position instead of prev_id" do
          let(:prev_id) { nil }
          let(:position) { "1" }

          it "moves the work_package to the requested position" do
            subject

            expect(work_package_in_sprint.reload).to have_attributes(sprint_id: nil, backlog_bucket_id: nil, position: 1)
          end
        end
      end

      context "with a Backlog bucket as target" do
        let(:bucket) { create(:backlog_bucket, name: "My Bucket", project:) }
        let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
        let(:list_type) { "backlog_bucket" }
        let(:list_id) { bucket.id }
        let(:prev_id) { bucket_items.first.id }

        it "replaces the sprints and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
        end

        context "when the project is configured to exclude the work packages status from backlogs" do
          before do
            project.done_statuses << status
          end

          include_examples "shows a flash message after moving a work package that turns invisible", "My Bucket"
        end

        context "when the project is configured to exclude the work packages type from backlogs" do
          before do
            project.backlog_excluded_types << type_feature
          end

          include_examples "shows a flash message after moving a work package that turns invisible", "My Bucket"
        end

        context "when the active bucket filter hides the target bucket" do
          let(:filter_params) { { bucket_ids: ["inbox"] } }

          include_examples "shows a flash message after moving a work package that turns invisible", "My Bucket"
        end

        it "moves the work_package into the bucket at the given position" do
          response

          expect(work_package_in_sprint.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end
      end
    end

    context "with an optimistic same-list move (drag)" do
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { "" }
      let(:optimistic) { "true" }

      it "dispatches the moved event and does not reload the frame", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dispatchEvent"
        expect(response).not_to have_turbo_stream action: "turbo_frame_reload"
      end
    end

    context "with an optimistic blank-anchor move that did not land on top" do
      let!(:other_item) { create(:work_package, status:, sprint:, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { "" }
      let(:optimistic) { "true" }

      before do
        # The real service always prepends on a blank prev_id, so the anchor
        # check's failure branch is unreachable through it; inject a result
        # that stayed mid-list (as a concurrent reorder could leave it).
        other_item.update_column(:position, 1)
        work_package_in_sprint.update_column(:position, 2)

        service = instance_double(Backlogs::WorkPackages::UpdateService)
        allow(Backlogs::WorkPackages::UpdateService).to receive(:new).and_return(service)
        allow(service).to receive(:call).and_return(ServiceResult.success(result: work_package_in_sprint.reload))
      end

      it "reloads the frame instead of trusting the top insert", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with an optimistic same-list move after a valid predecessor" do
      let!(:first_item) { create(:work_package, status:, sprint:, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { first_item.id }
      let(:optimistic) { "true" }

      it "skips the reload because the requested anchor was honoured", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dispatchEvent"
        expect(response).not_to have_turbo_stream action: "turbo_frame_reload"
      end
    end

    context "with an optimistic same-list move whose prev_id has left the list" do
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      # A predecessor that is not in the target sprint: move_after cannot
      # resolve it and silently falls back to the top, so the persisted order
      # diverges from the optimistic client order. The frame must reload to
      # reconcile rather than trust the stale client placement.
      let(:stray_prev) { create(:work_package, status:, project:) }
      let(:prev_id) { stray_prev.id }
      let(:optimistic) { "true" }

      it "reloads the frame instead of trusting the client order", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with an optimistic same-list move without any anchor (malformed)" do
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:optimistic) { "true" }

      # A nil param still reaches the controller as a blank string, but blank
      # means "insert at the top"; a missing anchor needs the key to be absent.
      subject(:response) do
        put :move, params: { project_id:, id:, list_type:, list_id:, optimistic: }, format: :turbo_stream
      end

      it "reloads the frame because the claimed order cannot be verified", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with an optimistic same-list move by position instead of prev_id" do
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { nil }
      let(:position) { "1" }
      let(:optimistic) { "true" }

      it "reloads the frame instead of trusting the client order", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with a same-list move from a client not flagging it optimistic" do
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { "" }
      let(:optimistic) { "false" }

      it "reloads the frame", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with an optimistic cross-list move" do
      let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { other_sprint.id }
      let(:prev_id) { "" }
      let(:optimistic) { "true" }

      it "reloads the frame because the list changed", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                              target: "backlogs_container"
      end
    end

    context "with Inbox as source (no sprint_id)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:id) { inbox_work_package.id }

      context "with a Sprint as target" do
        let(:target_sprint) { create(:sprint, name: "Target Sprint", project:) }
        let(:list_type) { "sprint" }
        let(:list_id) { target_sprint.id }

        it "replaces the sprints and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"

          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package to the sprint" do
          response

          expect(inbox_work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket_id: nil, position: 1)
        end
      end

      context "with the same Inbox as target" do
        let!(:inbox_items) { create_list(:work_package, 5, project:, status:) }
        let(:list_type) { "inbox" }
        let(:prev_id) { inbox_items.first.id }

        it "replaces only the inbox component without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work package to position 2" do
          response

          expect(inbox_work_package.reload).to have_attributes(sprint: nil, backlog_bucket: nil, position: 2)
        end
      end

      context "with a Backlog bucket as target" do
        let(:bucket) { create(:backlog_bucket, project:) }
        let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
        let(:list_type) { "backlog_bucket" }
        let(:list_id) { bucket.id }
        let(:prev_id) { bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work package into the bucket to position 2" do
          response

          expect(inbox_work_package.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end
      end
    end

    context "with a Backlog bucket as source" do
      let(:bucket) { create(:backlog_bucket, project:) }
      let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
      let(:bucket_work_package) { bucket_items.last }
      let(:id) { bucket_work_package.id }

      context "with a Sprint as target" do
        let(:target_sprint) { create(:sprint, name: "Target Sprint", project:) }
        let(:list_type) { "sprint" }
        let(:list_id) { target_sprint.id }

        it "replaces the sprints and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package into the sprint" do
          response

          expect(bucket_work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket: nil, position: 1)
        end
      end

      context "with the Inbox as target" do
        let!(:existing_inbox_item) { create(:work_package, project:, status:, position: 1) }
        let(:list_type) { "inbox" }
        let(:prev_id) { existing_inbox_item.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package to the inbox at the given position" do
          response

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket_id: nil, sprint_id: nil, position: 2)
        end
      end

      context "with the same Backlog bucket as target" do
        let(:list_type) { "backlog_bucket" }
        let(:list_id) { bucket.id }
        let(:prev_id) { bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "reorders the work_package within the bucket" do
          response

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end
      end

      context "with another Backlog bucket as target" do
        let(:other_bucket) { create(:backlog_bucket, project:) }
        let!(:other_bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: other_bucket) }
        let(:list_type) { "backlog_bucket" }
        let(:list_id) { other_bucket.id }
        let(:prev_id) { other_bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload",
                                                target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package into the other bucket at the given position" do
          response

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket: other_bucket, sprint_id: nil, position: 2)
        end
      end
    end

    context "when service call fails" do
      let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { other_sprint.id }
      let(:service_result) { ServiceResult.failure(message: "Something went wrong") }

      before do
        update_service = instance_double(Backlogs::WorkPackages::UpdateService, call: service_result)

        allow(Backlogs::WorkPackages::UpdateService)
          .to receive(:new)
          .and_return(update_service)
      end

      it "renders an error flash with 422", :aggregate_failures do
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}"
        expect(response).not_to have_turbo_stream action: "liveRegion"
      end
    end

    context "with a non-optimistic move to another sprint (dialog move)" do
      let(:other_sprint) { create(:sprint, name: "Sprint 2", project:) }
      let!(:wp_in_target) { create(:work_package, status:, sprint: other_sprint, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { other_sprint.id }
      let(:prev_id) { wp_in_target.id }

      it "streams a live region announcement with the new position" do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "liveRegion"
        # The liveRegion stream carries its message as an attribute on the
        # <turbo-stream> element itself (see render_live_region_update_message),
        # not inside a <template>, so we assert against the raw body.
        expect(response.body).to include("#{work_package_in_sprint.to_fs(:caption)} moved to Sprint 2, position 2 of 2")
      end
    end

    context "with a non-optimistic same-list move that changes only the position" do
      let!(:predecessor) { create(:work_package, status:, sprint:, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { predecessor.id }

      before do
        # Start the moved work package at the top so moving it after the
        # predecessor changes its position without changing its list.
        work_package_in_sprint.move_after(prev_id: nil)
      end

      it "streams a live region announcement with the new position" do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "liveRegion"
        expect(response.body).to include("#{work_package_in_sprint.to_fs(:caption)} moved to Agile Sprint 1, position 2 of 2")
      end
    end

    context "with an optimistic move (client announces)" do
      let!(:other_wp_in_sprint) { create(:work_package, status:, sprint:, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { other_wp_in_sprint.id }
      let(:optimistic) { "true" }

      it "does not stream a live region announcement" do
        expect(response).to be_successful
        expect(response).not_to have_turbo_stream action: "liveRegion"
      end
    end

    context "with an optimistic cross-list move (client announces)" do
      let(:other_sprint) { create(:sprint, name: "Sprint 2", project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { other_sprint.id }
      let(:prev_id) { "" }
      let(:optimistic) { "true" }

      it "does not stream a live region announcement" do
        expect(response).to be_successful
        expect(response).not_to have_turbo_stream action: "liveRegion"
      end
    end

    context "with a non-optimistic same-list move that changes nothing" do
      let!(:predecessor) { create(:work_package, status:, sprint:, project:) }
      let(:list_type) { "sprint" }
      let(:list_id) { sprint.id }
      let(:prev_id) { predecessor.id }

      before do
        # Put the moved work package right after its requested predecessor
        # already, so the move is a persisted no-op.
        work_package_in_sprint.move_after(prev_id: predecessor.id)
      end

      it "does not stream a live region announcement" do
        expect(response).to be_successful
        expect(response).not_to have_turbo_stream action: "liveRegion"
      end
    end
  end

  describe "GET #menu" do
    let(:params) { { project_id: project.id, id: work_package_id } }
    let(:work_package_id) { work_package.id }

    subject(:response) { get :menu, params:, format: :html }

    context "when work_package has no sprint (inbox item)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:work_package_id) { inbox_work_package.id }

      it "returns deferred action menu list HTML for inbox items" do
        expect(response).to have_http_status :ok
        expect(body).to include(I18n.t(:"js.button_open_details"))
      end
    end

    it "returns deferred action menu list HTML", :aggregate_failures do
      expect(response).to have_http_status :ok
      expect(body).to include(I18n.t(:"js.button_open_details"))
    end

    context "when assignable sprints exist" do
      let!(:other_open_sprint) { create(:sprint, name: "Sprint 2", project:) }

      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes ordered project sprint candidates to the menu component" do
        response

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(sprint_ids: Sprint.assignable(project:, user:).order_by_date.ids))
      end
    end

    context "when backlog buckets exist" do
      let!(:buckets) { create_list(:backlog_bucket, 2, project:) }

      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes alphabetically ordered project bucket candidates to the menu component" do
        response

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(bucket_ids: buckets.sort_by(&:name).map(&:id)))
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end

    # The client-side sortable-lists--item controller now gates first/last availability at
    # runtime (see AGILE-322); the server always renders all four move items when the user
    # may manage sprint items, regardless of the work package's position in its list.
    context "with sprint source" do
      let!(:sprint_items) { create_list(:work_package, 3, status:, sprint:, project:) }
      let(:work_package_id) { sprint_items.first.id }

      it "renders all four move items regardless of position", :aggregate_failures do
        expect(body).to include(I18n.t(:label_sort_highest))
        expect(body).to include(I18n.t(:label_sort_higher))
        expect(body).to include(I18n.t(:label_sort_lower))
        expect(body).to include(I18n.t(:label_sort_lowest))
      end
    end

    context "with inbox source" do
      let!(:inbox_items) { create_list(:work_package, 3, status:, project:) }
      let(:work_package_id) { inbox_items.last.id }

      it "renders all four move items regardless of position", :aggregate_failures do
        expect(body).to include(I18n.t(:label_sort_highest))
        expect(body).to include(I18n.t(:label_sort_higher))
        expect(body).to include(I18n.t(:label_sort_lower))
        expect(body).to include(I18n.t(:label_sort_lowest))
      end
    end

    context "with backlog bucket source" do
      let!(:backlog_bucket) { create(:backlog_bucket, project:) }
      let(:lone_item) { create(:work_package, project:, status:, backlog_bucket:) }
      let(:work_package_id) { lone_item.id }

      it "renders all four move items even for a lone item in its list", :aggregate_failures do
        expect(response).to have_http_status :ok
        expect(body).to include(I18n.t(:label_sort_highest))
        expect(body).to include(I18n.t(:label_sort_higher))
        expect(body).to include(I18n.t(:label_sort_lower))
        expect(body).to include(I18n.t(:label_sort_lowest))
      end
    end
  end

  describe "GET #add_existing_dialog" do
    let(:sprint) { create(:sprint, name: "Sprint 1", project:) }
    let(:bucket) { create(:backlog_bucket, name: "My Bucket", project:) }

    let(:form_action) { "backlogs/work_packages/add_existing?#{CGI.escapeHTML(list_params.to_query)}" }

    subject(:response) { get :add_existing_dialog, params: { project_id: project.id, **list_params }, format: :turbo_stream }

    context "with a Sprint as target" do
      let(:list_params) { { list_type: "sprint", list_id: sprint.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "has a dialog title" do
        expect(body).to include("Add existing work package")
      end

      it "sets the form action to the add_existing endpoint with the sprint target" do
        expect(body).to include(form_action)
      end
    end

    context "with a Backlog bucket as target" do
      let(:list_params) { { list_type: "backlog_bucket", list_id: bucket.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "has a dialog title" do
        expect(body).to include("Add existing work package")
      end

      it "sets the form action to the add_existing endpoint with the bucket target" do
        expect(body).to include(form_action)
      end
    end

    context "with Inbox as target" do
      let(:list_params) { { list_type: "inbox" } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "has a dialog title" do
        expect(body).to include("Add existing work package")
      end

      it "sets the form action to the add_existing endpoint with the inbox target" do
        expect(body).to include(form_action)
      end
    end

    context "with a Backlog bucket that can't be found" do
      let(:list_params) { { list_type: "backlog_bucket", list_id: bucket.id + 1 } }

      it "responds with 404 and an error flash instead of a dialog", :aggregate_failures do
        expect(response).to have_http_status :not_found
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "dialog"
      end
    end

    context "with a Sprint that can't be found" do
      let(:list_params) { { list_type: "sprint", list_id: sprint.id + 1 } }

      it "responds with 404 and an error flash instead of a dialog", :aggregate_failures do
        expect(response).to have_http_status :not_found
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "dialog"
      end
    end

    context "with no list params" do
      let(:list_params) { {} }

      it "responds with 422 and an error flash instead of a blank dialog", :aggregate_failures do
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "dialog"
      end
    end

    context "with an invalid list_type" do
      let(:list_params) { { list_type: "garbage" } }

      it "responds with 422 and an error flash instead of a blank dialog", :aggregate_failures do
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "dialog"
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }
      let(:list_params) { { list_type: "inbox" } }

      it "responds with 403" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }
      let(:list_params) { { list_type: "inbox" } }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "POST #add_existing" do
    shared_let(:sprint) { create(:sprint, name: "Sprint 1", project:) }
    shared_let(:target_sprint) { create(:sprint, name: "Sprint 2", project:) }
    shared_let(:bucket) { create(:backlog_bucket, name: "Bucket 1", project:) }
    shared_let(:target_bucket) { create(:backlog_bucket, name: "Bucket 2", project:) }

    let(:work_package_id) { work_package.id }

    subject(:response) do
      post :add_existing, params: { project_id: project.id, work_package_id:, **list_params }, format: :turbo_stream
    end

    context "when the work package is in a sprint" do
      let(:work_package) { create(:work_package, status:, sprint:, project:) }

      context "with another sprint as target" do
        let(:list_params) { { list_type: "sprint", list_id: target_sprint.id } }

        it "responds with success and reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package to the target sprint" do
          response

          expect(work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket_id: nil)
        end
      end

      context "with inbox as target" do
        let(:list_params) { { list_type: "inbox" } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package to the inbox" do
          response

          expect(work_package.reload).to have_attributes(sprint_id: nil, backlog_bucket_id: nil)
        end

        context "when the work package turns invisible (excluded status)" do
          before { project.done_statuses << status }

          include_examples "shows a flash message after moving a work package that turns invisible", "Inbox"
        end

        context "when the work package turns invisible (excluded type)" do
          before { project.backlog_excluded_types << type_feature }

          include_examples "shows a flash message after moving a work package that turns invisible", "Inbox"
        end
      end

      context "with a backlog bucket as target" do
        let(:list_params) { { list_type: "backlog_bucket", list_id: bucket.id } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package into the bucket" do
          response

          expect(work_package.reload).to have_attributes(sprint_id: nil, backlog_bucket: bucket)
        end

        context "when the work package turns invisible (excluded status)" do
          before { project.done_statuses << status }

          include_examples "shows a flash message after moving a work package that turns invisible", "Bucket 1"
        end
      end

      context "with the same sprint as target" do
        let(:list_params) { { list_type: "sprint", list_id: sprint.id } }

        it "responds with success and reloads the backlogs container without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "does not change the WP backlog container attributes" do
          expect { response }.not_to change { work_package.reload.attributes.slice(:sprint_id, :backlog_bucket_id) }
        end
      end
    end

    context "when the work package is in the inbox" do
      let(:work_package) { create(:work_package, status:, project:) }

      context "with a sprint as target" do
        let(:list_params) { { list_type: "sprint", list_id: target_sprint.id } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package into the sprint" do
          response

          expect(work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket_id: nil)
        end
      end

      context "with a backlog bucket as target" do
        let(:list_params) { { list_type: "backlog_bucket", list_id: bucket.id } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package into the bucket" do
          response

          expect(work_package.reload).to have_attributes(sprint_id: nil, backlog_bucket: bucket)
        end

        context "when the work package turns invisible (excluded type)" do
          before { project.backlog_excluded_types << type_feature }

          include_examples "shows a flash message after moving a work package that turns invisible", "Bucket 1"
        end
      end

      context "with inbox as target" do
        let(:list_params) { { list_type: "inbox" } }

        it "responds with success and reloads the backlogs container without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "does not change the WP backlog container attributes" do
          expect { response }.not_to change { work_package.reload.attributes.slice(:sprint_id, :backlog_bucket_id) }
        end
      end
    end

    context "when the work package is in a backlog bucket" do
      shared_let(:work_package) { create(:work_package, status:, project:, backlog_bucket: bucket) }

      context "with a sprint as target" do
        let(:list_params) { { list_type: "sprint", list_id: target_sprint.id } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package into the sprint" do
          response

          expect(work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket_id: nil)
        end
      end

      context "with inbox as target" do
        let(:list_params) { { list_type: "inbox" } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package to the inbox" do
          response

          expect(work_package.reload).to have_attributes(sprint_id: nil, backlog_bucket_id: nil)
        end
      end

      context "with another backlog bucket as target" do
        let(:list_params) { { list_type: "backlog_bucket", list_id: target_bucket.id } }

        it "reloads the backlogs container", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
        end

        it "moves the work package into the target bucket" do
          response

          expect(work_package.reload).to have_attributes(sprint_id: nil, backlog_bucket: target_bucket)
        end
      end

      context "with the same backlog bucket as target" do
        let(:list_params) { { list_type: "backlog_bucket", list_id: bucket.id } }

        it "responds with success and reloads the backlogs container without a flash", :aggregate_failures do
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "turbo_frame_reload", target: "backlogs_container"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "does not change the WP backlog container attributes" do
          expect { response }.not_to change { work_package.reload.attributes.slice(:sprint_id, :backlog_bucket_id) }
        end
      end
    end

    context "when service call fails" do
      let(:list_params) { { list_type: "inbox" } }

      before do
        allow(Backlogs::WorkPackages::UpdateService)
          .to receive(:new)
          .and_return(instance_double(Backlogs::WorkPackages::UpdateService, call: ServiceResult.failure(message: "Error")))
      end

      it "renders an error flash with 422", :aggregate_failures do
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}"
        expect(response).not_to have_turbo_stream action: "liveRegion"
      end
    end

    context "when the work package belongs to another project" do
      let(:work_package) { create(:work_package, status:) }
      let(:list_params) { { list_type: "inbox" } }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end

    context "without a list_type param" do
      let(:list_params) { {} }

      it "responds with 400" do
        expect(response).to have_http_status :bad_request
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }
      let(:list_params) { { list_type: "inbox" } }

      it "responds with 403" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }
      let(:list_params) { { list_type: "inbox" } }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET #move_to_sprint_dialog" do
    let!(:other_sprint) { create(:sprint) }
    let!(:displayed_sprints) { create_list(:sprint, 2, project:) }

    let(:params) { { project_id: project.id, id: work_package.id } }

    subject(:response) { get :move_to_sprint_dialog, params:, format: :turbo_stream }

    context "with a Sprint source" do
      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the existing sprints as list_id options" do
        subject

        displayed_sprints.each do |sprint|
          expect(body).to include(%(value="#{sprint.id}"))
        end
      end

      it "does not include the current sprint as a list_id option" do
        subject

        expect(body).not_to include(%(value="#{sprint.id}"))
      end

      it "does not include the other sprint" do
        subject

        expect(body).not_to include(%(value="#{other_sprint.id}"))
      end
    end

    context "with inbox source (no sprint_id)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:params) { { project_id: project.id, id: inbox_work_package.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "embeds the no-sprint work_packages path in the dialog form action URL" do
        expect(body).to include("backlogs/work_packages/#{inbox_work_package.id}/move")
        expect(body).not_to include("sprints")
      end

      it "includes the existing sprints as list_id options" do
        subject

        displayed_sprints.each do |sprint|
          expect(body).to include(%(value="#{sprint.id}"))
        end
      end

      it "does not include the other sprint" do
        subject

        expect(body).not_to include(%(value="#{other_sprint.id}"))
      end
    end

    context "with a Backlog bucket source" do
      let(:bucket) { create(:backlog_bucket, project:) }
      let(:bucket_work_package) { create(:work_package, status:, project:, backlog_bucket: bucket) }
      let(:params) { { project_id: project.id, id: bucket_work_package.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the available sprints in the dialog" do
        displayed_sprints.each do |sprint|
          expect(body).to include(%(value="#{sprint.id}"))
        end
      end

      it "does not include sprints from other projects" do
        subject

        expect(body).not_to include(%(value="#{other_sprint.id}"))
      end
    end

    context "when all=true is in params" do
      let(:params) { { project_id: project.id, id: work_package.id, all: "true" } }

      it "embeds the all query in the dialog form action URL" do
        expect(body).to include("all=true")
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }

      it "responds with 403" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET #move_to_bucket_dialog" do
    let!(:displayed_buckets) { create_list(:backlog_bucket, 2, project:) }
    let!(:other_bucket) { create(:backlog_bucket, project: create(:project)) }

    let(:params) { { project_id: project.id, id: work_package.id } }

    subject(:response) { get :move_to_bucket_dialog, params:, format: :turbo_stream }

    context "with a Sprint source" do
      it "responds with a dialog turbo stream", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the project buckets as list_id options" do
        subject

        displayed_buckets.each do |bucket|
          expect(body).to include(%(value="#{bucket.id}"))
        end
      end

      it "does not include buckets from other projects" do
        subject

        expect(body).not_to include(%(value="#{other_bucket.id}"))
      end
    end

    context "when the work package is in a bucket" do
      let(:current_bucket) { create(:backlog_bucket, project:) }
      let(:current_bucket_wp) { create(:work_package, status:, project:, backlog_bucket: current_bucket) }
      let(:params) { { project_id: project.id, id: current_bucket_wp.id } }

      it "responds with a dialog turbo stream" do
        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "excludes the current bucket from the options" do
        subject

        expect(body).not_to include(%(value="#{current_bucket.id}"))
      end

      it "includes the other project buckets" do
        displayed_buckets.each do |bucket|
          expect(body).to include(%(value="#{bucket.id}"))
        end
      end
    end

    context "when all=true is in params" do
      let(:params) { { project_id: project.id, id: work_package.id, all: "true" } }

      it "embeds the all query in the dialog form action URL" do
        expect(body).to include("all=true")
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }

      it "responds with 403" do
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        expect(response).to have_http_status :not_found
      end
    end
  end
end
