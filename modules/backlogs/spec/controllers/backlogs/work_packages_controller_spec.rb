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
  # Gets the html content of the template of the first turbo-stream with the
  # given action.
  def turbo_stream_template(action:)
    Nokogiri("<response>#{response.body}</response>").css("turbo-stream[action=#{action}] template").first.inner_html
  end

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }

  current_user { user }

  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project, types: [type_feature, type_task]) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }

  let(:sprint) { create(:sprint, name: "Agile Sprint 1", project:) }
  let(:work_package) { create(:work_package, status:, sprint:, project:, type: type_feature) }

  shared_examples "respecting the all param for inbox pagination" do
    context "with an inbox over the pagination threshold" do
      shared_let(:wps) { create_list(:work_package, 5, project:, status:) }

      before do
        stub_const("Backlogs::InboxComponent::TRUNCATE_MIDDLE", 2)
      end

      context "when all param is not present" do
        let(:all) { nil }

        it "replaces the inbox with a show-more row in the stream" do
          subject

          expect(response).to be_successful
          expect(response.body).to include("inbox_project_#{project.id}_show_more")
        end
      end

      context "when all=1" do
        let(:all) { "1" }

        it "replaces the inbox without a show-more row in the stream" do
          subject

          expect(response).to be_successful
          expect(response.body).not_to include("inbox_project_#{project.id}_show_more")
        end
      end
    end
  end

  describe "load_work_package" do
    let(:params) { { project_id: project.id, id: work_package.id } }

    subject { get :menu, params:, format: :html }

    it "assigns the visible work package", :aggregate_failures do
      subject

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
    let(:target_id) { nil }
    let(:prev_id) { nil }
    let(:all) { nil }
    let(:direction) { nil }

    subject do
      put :move, params: { project_id:, id:, target_id:, prev_id:, all:, direction: }, format: :turbo_stream
    end

    context "with a Sprint as source" do
      shared_examples "shows a flash message after moving a work package that turns invisible" do |target_name|
        it "shows a flash message after moving the work package" do
          subject

          message = "The work package was moved to #{target_name} but is not visible"
          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
          expect(turbo_stream_template(action: "flash")).to include(message)
        end
      end

      context "with the same Sprint as target" do
        let(:target_id) { "sprint:#{sprint.id}" }

        it "replaces the sprint component once and emits no flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-sprint-component-#{sprint.id}",
                                                method: "morph"
        end

        it "does not change the work_package's sprint and position" do
          expect do
            subject
            sprint.reload
          end.not_to change(sprint, :attributes)
        end
      end

      context "with another Sprint as target" do
        let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
        let(:target_id) { "sprint:#{other_sprint.id}" }

        it "responds with success and moves work_package to another Sprint", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response)
            .to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}", method: "morph"
          expect(response)
            .to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{other_sprint.id}", method: "morph"
          expect(assigns(:project)).to eq(project)
          expect(assigns(:work_package)).to eq(work_package_in_sprint)
        end

        it "moves the work_package to the target sprint" do
          subject

          expect(work_package_in_sprint.reload).to have_attributes(sprint: other_sprint, backlog_bucket_id: nil, position: 1)
        end
      end

      context "with Inbox as target" do
        let!(:existing_inbox_item) { create(:work_package, project:, status:, position: 1) }
        let(:target_id) { "inbox" }
        let(:prev_id) { existing_inbox_item.id }

        it "replaces the sprint and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response)
            .to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}", method: "morph"
          expect(response)
            .to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{project.id}", method: "morph"
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

        it "moves the work_package to the inbox at the given position" do
          subject

          expect(work_package_in_sprint.reload).to have_attributes(sprint_id: nil, backlog_bucket_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with a Backlog Bucket as target" do
        let(:bucket) { create(:backlog_bucket, name: "My Bucket", project:) }
        let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
        let(:target_id) { "backlog_bucket:#{bucket.id}" }
        let(:prev_id) { bucket_items.first.id }

        it "replaces the sprint and backlog components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-sprint-component-#{sprint.id}",
                                                method: "morph"
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
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

        it "moves the work_package into the bucket at the given position" do
          subject

          expect(work_package_in_sprint.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with direction param" do
        let(:direction) { "highest" }

        it "replaces the sprint component and responds with turbo streams", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(response)
            .to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}", method: "morph"
          expect(assigns(:work_package)).to eq(work_package_in_sprint)
        end

        it "moves the inbox item to the first position" do
          subject

          expect(work_package_in_sprint.reload).to have_attributes(backlog_bucket_id: nil, sprint:, position: 1)
        end

        context "when service call fails" do
          before do
            allow(Backlogs::WorkPackages::UpdateService)
              .to receive(:new)
              .and_return(instance_double(Backlogs::WorkPackages::UpdateService, call: ServiceResult.failure(message: "Error")))
          end

          it "renders an error flash with 422", :aggregate_failures do
            subject

            expect(response).to have_http_status :unprocessable_entity
            expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
            expect(response).not_to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}"
          end
        end
      end
    end

    context "with Inbox as source (no sprint_id)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:id) { inbox_work_package.id }

      context "with a Sprint as target" do
        let(:target_sprint) { create(:sprint, name: "Target Sprint", project:) }
        let(:target_id) { "sprint:#{target_sprint.id}" }

        it "replaces inbox and target sprint components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-sprint-component-#{target_sprint.id}"

          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package to the sprint" do
          subject

          expect(inbox_work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket_id: nil, position: 1)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with the same Inbox as target" do
        let!(:inbox_items) { create_list(:work_package, 5, project:, status:) }
        let(:target_id) { "inbox" }
        let(:prev_id) { inbox_items.first.id }

        it "replaces only the inbox component without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work package to position 2" do
          subject
          expect(inbox_work_package.reload).to have_attributes(sprint: nil, backlog_bucket: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with a Backlog Bucket as target" do
        let(:bucket) { create(:backlog_bucket, project:) }
        let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
        let(:target_id) { "backlog_bucket:#{bucket.id}" }
        let(:prev_id) { bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work package into the bucket to position 2" do
          subject
          expect(inbox_work_package.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with direction param" do
        let!(:inbox_items) { create_list(:work_package, 4, project:, status:) }
        let(:direction) { "highest" }

        it "replaces the backlog component and responds with turbo streams", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{project.id}"
          expect(assigns(:work_package)).to eq(inbox_work_package)
        end

        it "moves the inbox item to the first position" do
          subject

          expect(inbox_work_package.reload).to have_attributes(backlog_bucket_id: nil, sprint_id: nil, position: 1)
        end

        include_examples "respecting the all param for inbox pagination"
      end
    end

    context "with a Backlog bucket as source" do
      let(:bucket) { create(:backlog_bucket, project:) }
      let!(:bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: bucket) }
      let(:bucket_work_package) { bucket_items.last }
      let(:id) { bucket_work_package.id }

      context "with a Sprint as target" do
        let(:target_sprint) { create(:sprint, name: "Target Sprint", project:) }
        let(:target_id) { "sprint:#{target_sprint.id}" }

        it "replaces the backlog and sprint components without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-sprint-component-#{target_sprint.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package into the sprint" do
          subject

          expect(bucket_work_package.reload).to have_attributes(sprint: target_sprint, backlog_bucket: nil, position: 1)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with the Inbox as target" do
        let!(:existing_inbox_item) { create(:work_package, project:, status:, position: 1) }
        let(:target_id) { "inbox" }
        let(:prev_id) { existing_inbox_item.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package to the inbox at the given position" do
          subject

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket_id: nil, sprint_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with the same Backlog Bucket as target" do
        let(:target_id) { "backlog_bucket:#{bucket.id}" }
        let(:prev_id) { bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "reorders the work_package within the bucket" do
          subject

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket: bucket, sprint_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with another Backlog Bucket as target" do
        let(:other_bucket) { create(:backlog_bucket, project:) }
        let!(:other_bucket_items) { create_list(:work_package, 2, project:, status:, backlog_bucket: other_bucket) }
        let(:target_id) { "backlog_bucket:#{other_bucket.id}" }
        let(:prev_id) { other_bucket_items.first.id }

        it "replaces only the backlog component without a flash", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace",
                                                target: "backlogs-backlog-component-#{project.id}"
          expect(response).not_to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        end

        it "moves the work_package into the other bucket at the given position" do
          subject

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket: other_bucket, sprint_id: nil, position: 2)
        end

        include_examples "respecting the all param for inbox pagination"
      end

      context "with direction param" do
        let(:direction) { "highest" }

        it "replaces the backlog component and responds with turbo streams", :aggregate_failures do
          subject

          expect(response).to be_successful
          expect(response).to have_turbo_stream action: "replace", target: "backlogs-backlog-component-#{project.id}"
          expect(assigns(:work_package)).to eq(bucket_work_package)
        end

        it "moves the work_package to the first position within the bucket" do
          subject

          expect(bucket_work_package.reload).to have_attributes(backlog_bucket_id: bucket.id, sprint_id: nil, position: 1)
        end

        include_examples "respecting the all param for inbox pagination"
      end
    end

    context "when service call fails" do
      let(:other_sprint) { create(:sprint, name: "Agile Sprint 2", project:) }
      let(:target_id) { "sprint:#{other_sprint.id}" }
      let(:service_result) { ServiceResult.failure(message: "Something went wrong") }

      before do
        update_service = instance_double(Backlogs::WorkPackages::UpdateService, call: service_result)

        allow(Backlogs::WorkPackages::UpdateService)
          .to receive(:new)
          .and_return(update_service)
      end

      it "renders an error flash with 422", :aggregate_failures do
        subject

        expect(response).to have_http_status :unprocessable_entity
        expect(response).to have_turbo_stream action: "flash", target: "op-primer-flash-component"
        expect(response).not_to have_turbo_stream action: "replace", target: "backlogs-sprint-component-#{sprint.id}"
      end
    end
  end

  describe "GET #menu" do
    let(:params) { { project_id: project.id, id: work_package_id } }
    let(:work_package_id) { work_package.id }

    subject { get :menu, params:, format: :html }

    context "when work_package has no sprint (inbox item)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:work_package_id) { inbox_work_package.id }

      it "returns deferred action menu list HTML for inbox items" do
        subject

        expect(response).to have_http_status :ok
        expect(response.body).to include(I18n.t(:"js.button_open_details"))
      end
    end

    it "returns deferred action menu list HTML", :aggregate_failures do
      subject

      expect(response).to have_http_status :ok
      expect(response.body).to include(I18n.t(:"js.button_open_details"))
    end

    context "when all=1 is in params" do
      let(:params) { { project_id: project.id, id: work_package_id, all: "1" } }

      it "embeds the all query in deferred action URLs" do
        subject

        expect(response.body).to match(/all=1/)
      end
    end

    context "when another open sprint exists" do
      let!(:other_open_sprint) { create(:sprint, name: "Sprint 2", project:) }

      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes open_sprints_exist: true to the menu component" do
        subject

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(open_sprints_exist: true))
      end
    end

    context "when no other open sprints exist" do
      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes open_sprints_exist: false to the menu component" do
        subject

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(open_sprints_exist: false))
      end
    end

    context "when other backlog buckets exist" do
      let!(:buckets) { create_list(:backlog_bucket, 2, project:) }

      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes other_buckets_exist: true to the menu component" do
        subject

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(other_buckets_exist: true))
      end
    end

    context "when no backlog buckets exist" do
      before { allow(Backlogs::WorkPackageCardMenuComponent).to receive(:new).and_call_original }

      it "passes other_buckets_exist: false to the menu component" do
        subject

        expect(Backlogs::WorkPackageCardMenuComponent)
          .to have_received(:new)
          .with(hash_including(other_buckets_exist: false))
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "with sprint source" do
      let!(:sprint_items)       { create_list(:work_package, 3, status:, sprint:, project:) }
      let!(:other_sprint)       { create(:sprint, name: "Other Sprint", project:) }
      let!(:other_sprint_items) { create_list(:work_package, 10, status:, sprint: other_sprint, project:) }
      let!(:inbox_items)        { create_list(:work_package, 10, status:, project:) }

      context "for the first item" do
        let(:work_package_id) { sprint_items.first.id }

        it "scopes max_position to the sprint (first item has only downward actions)" do
          subject

          expect(response.body).not_to include(I18n.t(:label_sort_highest))
          expect(response.body).to include(I18n.t(:label_sort_lower))
        end
      end

      context "for the last item" do
        let(:work_package_id) { sprint_items.last.id }

        it "scopes max_position to the sprint (last item has only upward actions)" do
          subject

          expect(response.body).to include(I18n.t(:label_sort_highest))
          expect(response.body).not_to include(I18n.t(:label_sort_lower))
        end

        context "when a closed work package exists in the sprint" do
          let!(:closed_status) { create(:status, name: "Closed", is_closed: true) }
          let!(:closed_sprint_item) { create(:work_package, status: closed_status, sprint:, project:) }

          it "includes closed work packages in max_position so the last open item can still move down" do
            # sprint_items.last is at position 3; closed_sprint_item occupies position 4
            # max_position = 4 (closed included) → last open item is not at the bottom
            subject

            expect(response.body).to include(I18n.t(:label_sort_lower))
          end
        end
      end
    end

    context "with inbox source" do
      let!(:inbox_items)  { create_list(:work_package, 3, status:, project:) }
      let!(:sprint_items) { create_list(:work_package, 10, status:, project:, sprint:) }

      context "for the first item" do
        let(:work_package_id) { inbox_items.first.id }

        it "scopes max_position to the inbox (first item has only downward actions)" do
          subject

          expect(response.body).not_to include(I18n.t(:label_sort_highest))
          expect(response.body).to include(I18n.t(:label_sort_lower))
        end
      end

      context "for the last item" do
        let(:work_package_id) { inbox_items.last.id }

        it "scopes max_position to the inbox (last item has only upward actions)" do
          subject

          expect(response.body).to include(I18n.t(:label_sort_highest))
          expect(response.body).not_to include(I18n.t(:label_sort_lower))
        end

        context "when a closed work package exists in the inbox" do
          let!(:closed_status) { create(:status, name: "Closed", is_closed: true) }
          let!(:closed_inbox_item) { create(:work_package, status: closed_status, project:) }

          it "excludes closed work packages from max_position so the last open item is at the bottom" do
            # inbox_items.last is at position 3; closed_inbox_item occupies position 4
            # max_position = 3 (closed excluded) → last open item is at the bottom
            subject

            expect(response.body).not_to include(I18n.t(:label_sort_lower))
          end
        end
      end
    end

    context "with backlog bucket source" do
      let!(:backlog_bucket) { create(:backlog_bucket, project:) }
      let!(:bucket_items) { create_list(:work_package, 3, project:, status:, backlog_bucket:) }

      context "with a single item" do
        let(:lone_bucket) { create(:backlog_bucket, project:) }
        let(:lone_item) { create(:work_package, project:, status:, backlog_bucket: lone_bucket) }
        let(:work_package_id) { lone_item.id }

        it "scopes max_position to the bucket (lone item has no move actions)" do
          subject

          expect(response).to have_http_status :ok
          expect(response.body).not_to include(I18n.t(:label_sort_highest))
          expect(response.body).not_to include(I18n.t(:label_sort_lower))
        end
      end

      context "for the first item" do
        let(:work_package_id) { bucket_items.first.id }

        it "scopes max_position to the bucket (first item has only downward actions)" do
          subject

          expect(response.body).not_to include(I18n.t(:label_sort_highest))
          expect(response.body).to include(I18n.t(:label_sort_lower))
        end
      end

      context "for the last item" do
        let(:work_package_id) { bucket_items.last.id }

        it "scopes max_position to the bucket (last item has only upward actions)" do
          subject

          expect(response.body).to include(I18n.t(:label_sort_highest))
          expect(response.body).not_to include(I18n.t(:label_sort_lower))
        end

        context "when a closed work package exists in the bucket" do
          let!(:closed_status) { create(:status, name: "Closed", is_closed: true) }
          let!(:closed_bucket_item) { create(:work_package, status: closed_status, project:, backlog_bucket:) }

          it "excludes closed work packages from max_position so the last open item is at the bottom" do
            # bucket_items.last is at position 3; closed_bucket_item occupies position 4
            # max_position = 3 (closed excluded) → last open item is at the bottom
            subject

            expect(response.body).not_to include(I18n.t(:label_sort_lower))
          end
        end
      end
    end
  end

  describe "GET #move_to_sprint_dialog" do
    let!(:other_sprint) { create(:sprint) }
    let!(:displayed_sprints) { create_list(:sprint, 2, project:) }

    let(:params) { { project_id: project.id, id: work_package.id } }

    subject { get :move_to_sprint_dialog, params:, format: :turbo_stream }

    context "with a Sprint source" do
      it "responds with a dialog turbo stream", :aggregate_failures do
        subject

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the existing sprints in the target_id" do
        subject

        displayed_sprints.each do |sprint|
          expect(response.body).to include("sprint:#{sprint.id}")
        end
      end

      it "does not include the current sprints from the target_id" do
        subject

        expect(response.body).not_to include("sprint:#{sprint.id}")
      end

      it "does not include the other sprint" do
        subject

        expect(response.body).not_to include("sprint:#{other_sprint.id}")
      end
    end

    context "with inbox source (no sprint_id)" do
      let(:inbox_work_package) { create(:work_package, status:, project:) }
      let(:params) { { project_id: project.id, id: inbox_work_package.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        subject

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "embeds the no-sprint work_packages path in the dialog form action URL" do
        subject

        expect(response.body).to include("backlogs/work_packages/#{inbox_work_package.id}/move")
        expect(response.body).not_to include("sprints")
      end

      it "includes the existing sprints in the target_id" do
        subject

        displayed_sprints.each do |sprint|
          expect(response.body).to include("sprint:#{sprint.id}")
        end
      end

      it "does not include the other sprint" do
        subject

        expect(response.body).not_to include("sprint:#{other_sprint.id}")
      end
    end

    context "with a Backlog bucket source" do
      let(:bucket) { create(:backlog_bucket, project:) }
      let(:bucket_work_package) { create(:work_package, status:, project:, backlog_bucket: bucket) }
      let(:params) { { project_id: project.id, id: bucket_work_package.id } }

      it "responds with a dialog turbo stream", :aggregate_failures do
        subject

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the available sprints in the dialog" do
        subject

        displayed_sprints.each do |sprint|
          expect(response.body).to include("sprint:#{sprint.id}")
        end
      end

      it "does not include sprints from other projects" do
        subject

        expect(response.body).not_to include("sprint:#{other_sprint.id}")
      end
    end

    context "when all=1 is in params" do
      let(:params) { { project_id: project.id, id: work_package.id, all: "1" } }

      it "embeds the all query in the dialog form action URL" do
        subject

        expect(response.body).to match(/all=1/)
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }

      it "responds with 403" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        subject
        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "GET #move_to_bucket_dialog" do
    let!(:displayed_buckets) { create_list(:backlog_bucket, 2, project:) }
    let!(:other_bucket) { create(:backlog_bucket, project: create(:project)) }

    let(:params) { { project_id: project.id, id: work_package.id } }

    subject { get :move_to_bucket_dialog, params:, format: :turbo_stream }

    context "with a Sprint source" do
      it "responds with a dialog turbo stream", :aggregate_failures do
        subject

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "includes the project buckets in the target_id options" do
        subject

        displayed_buckets.each do |bucket|
          expect(response.body).to include("backlog_bucket:#{bucket.id}")
        end
      end

      it "does not include buckets from other projects" do
        subject

        expect(response.body).not_to include("backlog_bucket:#{other_bucket.id}")
      end
    end

    context "when the work package is in a bucket" do
      let(:current_bucket) { create(:backlog_bucket, project:) }
      let(:current_bucket_wp) { create(:work_package, status:, project:, backlog_bucket: current_bucket) }
      let(:params) { { project_id: project.id, id: current_bucket_wp.id } }

      it "responds with a dialog turbo stream" do
        subject

        expect(response).to be_successful
        expect(response).to have_turbo_stream action: "dialog"
      end

      it "excludes the current bucket from the options" do
        subject

        expect(response.body).not_to include("backlog_bucket:#{current_bucket.id}")
      end

      it "includes the other project buckets" do
        subject

        displayed_buckets.each do |bucket|
          expect(response.body).to include("backlog_bucket:#{bucket.id}")
        end
      end
    end

    context "when all=1 is in params" do
      let(:params) { { project_id: project.id, id: work_package.id, all: "1" } }

      it "embeds the all query in the dialog form action URL" do
        subject

        expect(response.body).to match(/all=1/)
      end
    end

    context "with a user lacking manage_sprint_items permission" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints view_work_packages] }) }

      it "responds with 403" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "with a user lacking project permission" do
      let(:user) { create(:user) }

      it "responds with 404" do
        subject
        expect(response).to have_http_status :not_found
      end
    end
  end
end
