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

RSpec.describe WorkPackageHierarchyRelationsController do
  shared_let(:user) { create(:admin) }
  shared_let(:task_type) { create(:type_task) }
  shared_let(:milestone_type) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [task_type, milestone_type]) }
  shared_let(:parent_work_package) { create(:work_package, subject: "parent", project:, type: task_type) }
  shared_let(:work_package) do
    create(:work_package, subject: "work_package", parent: parent_work_package, project:, type: task_type)
  end
  shared_let(:child_work_package) { create(:work_package, subject: "child", parent: work_package, project:, type: task_type) }

  current_user { user }

  describe "GET /work_packages/:work_package_id/hierarchy_relations/new" do
    before do
      allow(WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent)
        .to receive(:new)
        .and_call_original
    end

    it "renders the add child/parent dialog component via turbo stream according to the relation_type parameter" do
      # child
      get("new", params: { work_package_id: work_package.id, relation_type: "child" }, as: :turbo_stream)
      expect(response).to be_successful
      expect(WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent)
        .to have_received(:new)
        .with(work_package:, relation_type: Relation::TYPE_CHILD)

      # parent
      get("new", params: { work_package_id: work_package.id, relation_type: "parent" }, as: :turbo_stream)
      expect(response).to be_successful
      expect(WorkPackageRelationsTab::AddWorkPackageHierarchyDialogComponent)
        .to have_received(:new)
        .with(work_package:, relation_type: Relation::TYPE_PARENT)
    end

    context "when the indicated relation type is not valid (must be parent or child)" do
      it "replies with 422" do
        get("new", params: { work_package_id: work_package.id, relation_type: "invalid" }, as: :turbo_stream)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the relation type is not provided" do
      it "replies with 422" do
        get("new", params: { work_package_id: work_package.id }, as: :turbo_stream)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /work_packages/:work_package_id/hierarchy_relations" do
    context "when the relation type is child" do
      shared_let(:future_child_work_package) { create(:work_package, subject: "future_child", project:) }
      let(:relation_type) { "child" }

      it "creates a child relationship" do
        post("create", params: { work_package_id: work_package.id,
                                 work_package: { id: future_child_work_package.id },
                                 relation_type: },
                       as: :turbo_stream)
        expect(response).to have_http_status(:ok)
        expect(future_child_work_package.reload.parent).to eq(work_package)
      end

      it "can't create a child relationship for a milestone work package" do
        work_package.update(type: milestone_type)
        post("create", params: { work_package_id: work_package.id,
                                 work_package: { id: future_child_work_package.id },
                                 relation_type: },
                       as: :turbo_stream)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(future_child_work_package.reload.parent).to be_nil
      end

      context "when the child is invalid due to a required custom field" do
        shared_let(:custom_field) do
          create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
            project.enabled_variants.first.custom_fields << cf
            project.work_package_custom_fields << cf
          end
        end

        it "the creation call still succeeds" do
          post("create", params: { work_package_id: work_package.id,
                                   work_package: { id: future_child_work_package.id },
                                   relation_type: },
                         as: :turbo_stream)
          expect(response).to have_http_status(:ok)
          expect(future_child_work_package.reload.parent).to eq(work_package)
        end
      end
    end

    context "when the relation type is parent" do
      shared_let(:future_parent_work_package) { create(:work_package, subject: "future_parent", project:) }
      let(:relation_type) { "parent" }

      it "creates a parent relationship" do
        post("create", params: { work_package_id: work_package.id,
                                 work_package: { id: future_parent_work_package.id },
                                 relation_type: },
                       as: :turbo_stream)
        expect(response).to have_http_status(:ok)
        expect(work_package.reload.parent).to eq(future_parent_work_package)
      end

      it "can create a parent relationship for a milestone work package" do
        work_package.update(type: milestone_type)
        post("create", params: { work_package_id: work_package.id,
                                 work_package: { id: future_parent_work_package.id },
                                 relation_type: },
                       as: :turbo_stream)
        expect(response).to have_http_status(:ok)
        expect(work_package.reload.parent).to eq(future_parent_work_package)
      end

      it "can not select a milestone work package as parent" do
        future_parent_work_package.update(type: milestone_type)
        post("create", params: { work_package_id: work_package.id,
                                 work_package: { id: future_parent_work_package.id },
                                 relation_type: },
                       as: :turbo_stream)
        expect(response).to have_http_status(:unprocessable_entity)
        # it's still parent_work_package and not future_parent_work_package
        expect(work_package.reload.parent).to eq(parent_work_package)
      end

      context "when the work package is invalid due to a required custom field" do
        shared_let(:custom_field) do
          create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
            project.enabled_variants.first.custom_fields << cf
            project.work_package_custom_fields << cf
          end
        end

        it "the creation call still succeeds" do
          post("create", params: { work_package_id: work_package.id,
                                   work_package: { id: future_parent_work_package.id },
                                   relation_type: },
                         as: :turbo_stream)
          expect(response).to have_http_status(:ok)
          expect(work_package.reload.parent).to eq(future_parent_work_package)
        end
      end
    end
  end

  describe "DELETE /work_packages/:work_package_id/children/:id" do
    def send_delete_request(related:)
      delete("destroy",
             params: { work_package_id: work_package.id,
                       id: related.id },
             as: :turbo_stream)
    end

    it "removes the hierarchy relationship between both work packages" do
      # remove a child
      send_delete_request(related: child_work_package)

      expect(response).to have_http_status(:ok)
      expect(child_work_package.reload.parent).to be_nil

      # remove the parent
      send_delete_request(related: parent_work_package)

      expect(response).to have_http_status(:ok)
      expect(work_package.reload.parent).to be_nil
    end

    it "renders the relations tab index component with the concerned work package" do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:replace_via_turbo_stream).and_call_original

      # remove a child
      send_delete_request(related: child_work_package)

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:)
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))

      # remove the parent
      send_delete_request(related: parent_work_package)

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:).twice
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent)).twice
    end

    it "updates dependent work packages" do
      allow(WorkPackages::UpdateAncestorsService).to receive(:new).and_call_original
      allow(WorkPackages::SetScheduleService).to receive(:new).and_call_original

      # remove a child
      send_delete_request(related: child_work_package)

      expect(WorkPackages::UpdateAncestorsService).to have_received(:new)
        .with(user: user, work_package: child_work_package)
      expect(WorkPackages::SetScheduleService).to have_received(:new)
        .with(a_hash_including(work_package: [child_work_package, work_package]))

      # remove the parent
      send_delete_request(related: parent_work_package)

      expect(WorkPackages::UpdateAncestorsService).to have_received(:new)
        .with(user: user, work_package:)
      expect(WorkPackages::SetScheduleService).to have_received(:new)
        .with(a_hash_including(work_package: [work_package, parent_work_package]))
    end

    context "when the child is invalid due to a required custom field" do
      shared_let(:custom_field) do
        create(:integer_wp_custom_field, is_required: true, is_for_all: true, default_value: nil) do |cf|
          project.enabled_variants.first.custom_fields << cf
          project.work_package_custom_fields << cf
        end
      end

      it "the deletion call still succeeds" do
        # remove a child
        send_delete_request(related: child_work_package)

        expect(response).to have_http_status(:ok)
        expect(child_work_package.reload.parent).to be_nil

        # remove the parent
        send_delete_request(related: parent_work_package)

        expect(response).to have_http_status(:ok)
        expect(work_package.reload.parent).to be_nil
      end
    end
  end
end
