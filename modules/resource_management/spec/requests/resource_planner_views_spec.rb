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

RSpec.describe "ResourcePlannerViews requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end

  let(:resource_planner) { create(:resource_planner, project:, principal: user) }
  let(:view) do
    ResourceWorkPackageList.create!(name: "Original", parent: resource_planner, project:, principal: user)
  end

  before { login_as user }

  describe "POST create" do
    subject(:perform) do
      post project_resource_planner_views_path(project, resource_planner),
           params: {
             view_class_name: "ResourceWorkPackageList",
             # `filter_mode` is submitted scoped to the `view` form, exactly as
             # the configure form renders it.
             view: { name: "Work packages", filter_mode: "automatic" },
             filters: [{ status_id: { operator: "o", values: [] } }].to_json
           },
           as: :turbo_stream
    end

    it "persists the view together with a query carrying the submitted filters" do
      expect { perform }.to change(ResourceWorkPackageList, :count).by(1)

      view = ResourceWorkPackageList.last
      expect(view.name).to eq("Work packages")
      expect(view.category).to eq("resource_management")
      expect(view.query).to be_a(Query)
      expect(view.query.name).to eq(I18n.t("resource_management.work_package_list.query_name", name: "Work packages"))
      expect(view.query.filters.map(&:name)).to contain_exactly(:status_id)
    end

    context "when the view is manually hand-picked" do
      subject(:perform) do
        post project_resource_planner_views_path(project, resource_planner),
             params: {
               view_class_name: "ResourceWorkPackageList",
               view: { name: "Hand-picked", filter_mode: "manual" },
               # The hidden filter form still serializes its (ignored) default state.
               filters: [{ status_id: { operator: "o", values: [] } }].to_json
             },
             as: :turbo_stream
      end

      it "sets up the query for manual sorting instead of applying the filters" do
        perform

        query = ResourceWorkPackageList.last.query
        expect(query).to be_manually_sorted
        expect(query.filters.map(&:name)).to contain_exactly(:manual_sort)
      end

      it "opens the edit dialog pre-selected on manual rather than automatic" do
        perform
        view = ResourceWorkPackageList.last

        get edit_project_resource_planner_view_path(project, resource_planner, view), as: :turbo_stream

        manual_radio = response.body[/<input[^>]*value="manual"[^>]*>/]
        expect(manual_radio).to include("checked")
      end
    end
  end

  describe "GET new (configure step)" do
    it "pre-fills the view name with the view type's label" do
      get new_project_resource_planner_view_path(project, resource_planner),
          params: { view_class_name: "ResourceWorkPackageList" },
          as: :turbo_stream

      expect(response).to have_http_status(:ok)
      name_field = response.body[/<input[^>]*name="view\[name\]"[^>]*>/]
      expect(name_field).to include(%(value="#{I18n.t('resource_management.view_types.resource_work_package_list.label')}"))
    end
  end

  describe "PATCH update" do
    subject(:perform) do
      patch project_resource_planner_view_path(project, resource_planner, view),
            params: { view: { name: "Renamed view" } },
            as: :turbo_stream
    end

    it "persists the new name" do
      perform

      expect(response).to have_http_status(:ok)
      expect(view.reload.name).to eq("Renamed view")
    end

    it "switches an automatic view to manual via the view-scoped filter_mode" do
      patch project_resource_planner_view_path(project, resource_planner, view),
            params: {
              view: { name: "Original", filter_mode: "manual" },
              filters: [{ status_id: { operator: "o", values: [] } }].to_json
            },
            as: :turbo_stream

      query = view.reload.query
      expect(query.filters.map(&:name)).to contain_exactly(:manual_sort)
      expect(query).to be_manually_sorted
    end

    it "closes the dialog and replaces the tab nav and content in place" do
      perform

      # Dialog is closed via a CSS selector target (not a bare id).
      expect(response.body).to include('action="closeDialog"')
      expect(response.body).to include('target="#edit-resource-planner-view-dialog"')

      # Tab nav and the view content are replaced rather than redirecting.
      expect(response.body).to include('action="replace"')
      expect(response.body).to include('target="resource-planners-sub-views-component"')
      expect(response.body).to include('target="resource-planner-views-content-component"')

      # The replaced tab nav reflects the new name.
      expect(response.body).to include("Renamed view")
    end

    context "when another user cannot see the private planner" do
      let(:other_user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

      before { login_as other_user }

      it "is not found and leaves the view unchanged" do
        perform

        expect(response).to have_http_status(:not_found)
        expect(view.reload.name).to eq("Original")
      end
    end
  end

  describe "work package picker for manually hand-picked views" do
    shared_let(:work_package) { create(:work_package, project:) }

    let(:manual_view) do
      ResourceWorkPackageList.create!(
        name: "Hand-picked",
        parent: resource_planner,
        project:,
        principal: user,
        query: Query.new_default(project:, user:).tap do |query|
          query.name = "Hand-picked query"
          query.add_filter("manual_sort", "ow", [])
          query.sort_criteria = [%w[manual_sorting asc]]
          query.save!
        end
      )
    end

    describe "GET new_work_package" do
      it "renders the search dialog" do
        get new_work_package_project_resource_planner_view_path(project, resource_planner, manual_view),
            as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(ResourcePlannerViews::WorkPackageList::AddWorkPackageDialogComponent::DIALOG_ID)
      end
    end

    describe "POST add_work_package" do
      subject(:perform) do
        post work_packages_project_resource_planner_view_path(project, resource_planner, manual_view),
             params: { work_package_id: work_package.id },
             as: :turbo_stream
      end

      it "appends the work package to the query and re-renders the list" do
        expect { perform }.to change { manual_view.query.ordered_work_packages.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(manual_view.query.ordered_work_packages.map(&:work_package)).to include(work_package)
        expect(response.body).to include('target="resource-planner-views-content-component"')
      end

      it "does not add the same work package twice" do
        manual_view.query.ordered_work_packages.create!(work_package:, position: 1)

        expect { perform }.not_to(change { manual_view.query.ordered_work_packages.count })
      end

      it "returns a client error for a work package outside the project" do
        other = create(:work_package)

        post work_packages_project_resource_planner_view_path(project, resource_planner, manual_view),
             params: { work_package_id: other.id },
             as: :turbo_stream

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "PUT move_work_package" do
      shared_let(:other_wp) { create(:work_package, project:) }

      before do
        manual_view.query.ordered_work_packages.create!(work_package:, position: 1)
        manual_view.query.ordered_work_packages.create!(work_package: other_wp, position: 2)
      end

      def ordered_ids
        manual_view.query.ordered_work_packages.order(:position).pluck(:work_package_id)
      end

      it "moves a work package down and re-packs positions" do
        put move_work_package_project_resource_planner_view_path(
          project, resource_planner, manual_view, work_package_id: work_package.id, direction: "down"
        ), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(ordered_ids).to eq([other_wp.id, work_package.id])
        expect(manual_view.query.ordered_work_packages.order(:position).pluck(:position)).to eq([1, 2])
      end

      it "moves a work package to the top" do
        put move_work_package_project_resource_planner_view_path(
          project, resource_planner, manual_view, work_package_id: other_wp.id, direction: "top"
        ), as: :turbo_stream

        expect(ordered_ids).to eq([other_wp.id, work_package.id])
      end
    end

    describe "PUT reorder_work_package (drag-and-drop drop)" do
      shared_let(:other_wp) { create(:work_package, project:) }

      before do
        manual_view.query.ordered_work_packages.create!(work_package:, position: 1)
        manual_view.query.ordered_work_packages.create!(work_package: other_wp, position: 2)
      end

      it "moves the work package to the dropped 1-based position and re-packs" do
        put reorder_work_package_project_resource_planner_view_path(
          project, resource_planner, manual_view, work_package_id: work_package.id
        ), params: { position: 2 }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(manual_view.query.ordered_work_packages.order(:position).pluck(:work_package_id))
          .to eq([other_wp.id, work_package.id])
      end

      it "renders the list inside the drag-and-drop container" do
        put reorder_work_package_project_resource_planner_view_path(
          project, resource_planner, manual_view, work_package_id: work_package.id
        ), params: { position: 1 }, as: :turbo_stream

        expect(response.body).to include('data-controller="generic-drag-and-drop"')
        expect(response.body).to include("data-draggable-type=\"#{ResourcePlannerViews::WorkPackageList::RowComponent::DRAGGABLE_TYPE}\"")
      end
    end

    describe "DELETE remove_work_package" do
      before { manual_view.query.ordered_work_packages.create!(work_package:, position: 1) }

      subject(:perform) do
        delete remove_work_package_project_resource_planner_view_path(
          project, resource_planner, manual_view, work_package_id: work_package.id
        ), as: :turbo_stream
      end

      it "drops the work package from the query and re-renders the list" do
        expect { perform }.to change { manual_view.query.ordered_work_packages.count }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('target="resource-planner-views-content-component"')
      end
    end

    describe "authorization for changing contents on a public planner" do
      let(:resource_planner) { create(:resource_planner, project:, principal: user, public: true) }

      subject(:perform) do
        post work_packages_project_resource_planner_view_path(project, resource_planner, manual_view),
             params: { work_package_id: work_package.id },
             as: :turbo_stream
      end

      context "as a non-owner with only view_resource_planners" do
        let(:viewer) do
          create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
        end

        before { login_as viewer }

        it "denies changing the contents" do
          expect { perform }.not_to(change { manual_view.query.ordered_work_packages.count })
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "as a non-owner with manage_public_resource_planners" do
        let(:manager) do
          create(:user,
                 member_with_permissions: {
                   project => %i[view_resource_planners manage_public_resource_planners view_work_packages]
                 })
        end

        before { login_as manager }

        it "allows changing the contents" do
          expect { perform }.to change { manual_view.query.ordered_work_packages.count }.by(1)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    describe "DELETE destroy" do
      before { manual_view.query.ordered_work_packages.create!(work_package:, position: 1) }

      it "deletes the view and purges its query and ordered work packages" do
        query_id = manual_view.query.id

        expect do
          delete project_resource_planner_view_path(project, resource_planner, manual_view), as: :turbo_stream
        end.to change(ResourceWorkPackageList, :count).by(-1)

        expect(response).to redirect_to(project_resource_planner_path(project, resource_planner))
        expect(response).to have_http_status(:see_other)
        expect(Query.exists?(query_id)).to be(false)
        expect(OrderedWorkPackage.where(query_id:)).to be_empty
      end

      it "repoints the planner's default view when the deleted view was the default" do
        resource_planner.update!(default_view_id: manual_view.id)

        delete project_resource_planner_view_path(project, resource_planner, manual_view), as: :turbo_stream

        expect(resource_planner.reload.default_view_id).not_to eq(manual_view.id)
      end

      context "when another user cannot manage the private planner" do
        let(:other_user) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

        before { login_as other_user }

        it "does not delete the view" do
          expect do
            delete project_resource_planner_view_path(project, resource_planner, manual_view), as: :turbo_stream
          end.not_to change(ResourceWorkPackageList, :count)
        end
      end
    end
  end
end
