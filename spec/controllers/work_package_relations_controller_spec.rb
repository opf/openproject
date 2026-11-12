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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageRelationsController do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:related_work_package) { create(:work_package, project:) }
  shared_let(:unrelated_work_package) { create(:work_package, project:) }
  shared_let(:relation, refind: true) do
    create(:relation,
           from: work_package,
           to: related_work_package,
           relation_type: Relation::TYPE_RELATES)
  end
  shared_let(:children) do
    create_list(:work_package, 2, parent: work_package, project:)
  end

  current_user { user }

  describe "GET /work_packages/:work_package_id/relations/new" do
    let(:new_relation) do
      build(:relation,
            from: work_package,
            to: nil,
            relation_type: Relation::TYPE_RELATES)
    end

    before do
      allow(WorkPackageRelationsTab::WorkPackageRelationDialogComponent)
        .to receive(:new)
        .and_call_original
      allow(controller).to receive(:respond_with_dialog).and_call_original
    end

    it "renders the relations new dialog" do
      get("new",
          params: { work_package_id: work_package.id,
                    relation_type: Relation::TYPE_RELATES },
          as: :turbo_stream)

      expect(WorkPackageRelationsTab::WorkPackageRelationDialogComponent)
        .to have_received(:new)
      expect(controller).to have_received(:respond_with_dialog)
    end
  end

  describe "GET /work_packages/:work_package_id/relations/:id/edit" do
    before do
      allow(WorkPackageRelationsTab::WorkPackageRelationDialogComponent)
        .to receive(:new)
        .and_call_original
      allow(controller).to receive(:respond_with_dialog).and_call_original
    end

    it "renders the relations edit dialog" do
      get("edit",
          params: { work_package_id: work_package.id, id: relation.id },
          as: :turbo_stream)

      expect(WorkPackageRelationsTab::WorkPackageRelationDialogComponent)
        .to have_received(:new)
        .with(work_package:, relation:)

      expect(controller).to have_received(:respond_with_dialog)
        .with(an_instance_of(WorkPackageRelationsTab::WorkPackageRelationDialogComponent))

      expect(response).to be_successful
    end
  end

  describe "POST /work_packages/:work_package_id/relations" do
    before do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:replace_via_turbo_stream).and_call_original
    end

    it "creates the relation" do
      post("create",
           params: { work_package_id: work_package.id,
                     relation: { to_id: unrelated_work_package.id,
                                 relation_type: Relation::TYPE_RELATES } },
           as: :turbo_stream)

      expect(response).to be_successful

      new_relation = Relation.last

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:, relation_to_scroll_to: new_relation)
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))
    end
  end

  describe "PATCH /work_packages/:work_package_id/relations/:id" do
    before do
      relation.update_column(:description, "Old relation description")
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:replace_via_turbo_stream).and_call_original
    end

    it "updates the relation description" do
      patch("update",
            params: { work_package_id: work_package.id,
                      id: relation.id,
                      relation: { description: "New fancy relation description" } },
            as: :turbo_stream)

      expect(relation.reload.description).to eq("New fancy relation description")

      expect(response).to be_successful

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:)
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))
    end
  end

  describe "DELETE /work_packages/:work_package_id/relations/:id" do
    before do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:replace_via_turbo_stream).and_call_original
    end

    it "deletes the relation" do
      delete("destroy", params: { work_package_id: work_package.id, id: relation.id }, as: :turbo_stream)

      expect(response).to be_successful

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:)
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))
      expect { relation.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does nothing if the given relation does not exist" do
      deleted_relation_id = relation.id
      relation.destroy
      delete("destroy", params: { work_package_id: work_package.id, id: deleted_relation_id }, as: :turbo_stream)

      expect(response).to be_successful

      expect(WorkPackageRelationsTab::IndexComponent).to have_received(:new)
        .with(work_package:)
      expect(controller).to have_received(:replace_via_turbo_stream)
        .with(component: an_instance_of(WorkPackageRelationsTab::IndexComponent))
    end
  end
end
