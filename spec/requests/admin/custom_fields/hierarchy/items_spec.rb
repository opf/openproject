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

RSpec.describe "Hierarchy item management", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:non_admin) { create(:user) }

  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:root) { custom_field.hierarchy_root }

  shared_examples "managing hierarchy items" do
    let!(:luke) { create(:hierarchy_item, parent: root, label: "Luke", short: "LS") }
    let!(:mara) { create(:hierarchy_item, parent: luke, label: "Mara", short: "MJ") }
    let!(:leia) { create(:hierarchy_item, parent: root, label: "Leia", short: "LO") }
    let!(:han) { create(:hierarchy_item, parent: root, label: "Han") }

    let(:labels_by_position) { root.descendants.reorder(:position_cache).pluck(:label) }

    let(:other_custom_field) { create(:hierarchy_wp_custom_field) }
    let!(:foreign_item) { create(:hierarchy_item, parent: other_custom_field.hierarchy_root, label: "Vader", short: "DV") }

    context "when not logged in" do
      it "redirects to the login" do
        get items_path

        expect(response).to redirect_to(signin_path(back_url: "http://test.host#{items_path}"))
      end
    end

    context "as a non-admin" do
      before { login_as non_admin }

      it "forbids viewing the items" do
        get items_path

        expect(response).to have_http_status(:forbidden)
      end

      it "forbids creating an item" do
        expect { post items_path, params: { label: "Ben" } }.not_to change(CustomField::Hierarchy::Item, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it "forbids updating an item" do
        patch "#{items_path}/#{luke.id}", params: { label: "Ben" }

        expect(response).to have_http_status(:forbidden)
        expect(luke.reload.label).to eq("Luke")
      end

      it "forbids reordering an item" do
        post "#{items_path}/#{han.id}/move", params: { new_sort_order: 0 }

        expect(response).to have_http_status(:forbidden)
        expect(han.reload.sort_order).to eq(2)
      end

      it "forbids changing the parent of an item" do
        post "#{items_path}/#{han.id}/change_parent",
             params: { custom_field_hierarchy_forms_new_parent_form_model: { new_parent: [{ value: luke.id }.to_json] } }

        expect(response).to have_http_status(:forbidden)
        expect(han.reload.parent).to eq(root)
      end

      it "forbids deleting an item" do
        expect { delete "#{items_path}/#{luke.id}" }.not_to change(CustomField::Hierarchy::Item, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as an admin" do
      before { login_as admin }

      describe "GET index" do
        it "lists the top-level items" do
          get items_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Luke", "Leia", "Han")
        end
      end

      describe "GET show" do
        it "lists the children of the item" do
          get "#{items_path}/#{luke.id}"

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Mara")
        end
      end

      describe "GET new" do
        it "renders the form for a top-level item" do
          get "#{items_path}/new", params: { position: 3 }

          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET new_child" do
        it "renders the form for a child item" do
          get "#{items_path}/#{luke.id}/new_child", params: { position: 1 }

          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET edit" do
        it "renders the form with the item" do
          get "#{items_path}/#{luke.id}/edit"

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Luke")
        end
      end

      describe "GET item_actions" do
        it "renders the actions of the item" do
          get "#{items_path}/#{luke.id}/item_actions"

          expect(response).to have_http_status(:ok)
        end
      end

      describe "GET delete" do
        it "renders the deletion dialog" do
          get "#{items_path}/#{luke.id}/delete", headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      describe "GET change_parent" do
        it "renders the change parent dialog" do
          get "#{items_path}/#{luke.id}/change_parent", headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      describe "POST create" do
        let(:create_params) { { label: "Ben", short: "OWK", sort_order: 3 } }

        subject(:create_request) { post items_path, params: create_params }

        it "appends a top-level item and redirects to the form for the next position" do
          expect { create_request }.to change(CustomField::Hierarchy::Item, :count).by(1)

          expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han Ben])
          expect(root.children.last).to have_attributes(short: "OWK", sort_order: 3)
          expect(response).to redirect_to("#{items_path}/new?position=4")
        end

        it "updates the position cache of the whole tree" do
          create_request

          expect(labels_by_position).to eq(%w[Luke Mara Leia Han Ben])
        end

        context "with a requested position" do
          let(:create_params) { { label: "Ben", sort_order: 1 } }

          it "inserts the item before the sibling at that position" do
            create_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Luke Ben Leia Han])
            expect(labels_by_position).to eq(%w[Luke Mara Ben Leia Han])
          end
        end

        context "for a child item" do
          let(:create_params) { { label: "Ben", short: "OWK", sort_order: 1 } }

          subject(:create_request) { post "#{items_path}/#{luke.id}/new_child", params: create_params }

          it "appends the item to the parent" do
            create_request

            expect(luke.reload.children.pluck(:label)).to eq(%w[Mara Ben])
            expect(labels_by_position).to eq(%w[Luke Mara Ben Leia Han])
          end
        end

        context "for a child item with a label used in another branch" do
          let(:create_params) { { label: "Mara", short: "MJ", sort_order: 0 } }

          subject(:create_request) { post "#{items_path}/#{leia.id}/new_child", params: create_params }

          it "creates the item" do
            expect { create_request }.to change(CustomField::Hierarchy::Item, :count).by(1)

            expect(leia.reload.children.pluck(:label)).to eq(%w[Mara])
          end
        end

        context "with a label used by a sibling in a different case" do
          let(:create_params) { { label: "lEIA", sort_order: 3 } }

          it "renders the form with an error" do
            expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

            expect(response).to have_http_status(:ok)
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "with a short used by a sibling in a different case" do
          let(:create_params) { { label: "Lando", short: "lo", sort_order: 3 } }

          it "renders the form with an error" do
            expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

            expect(response).to have_http_status(:ok)
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "without a label" do
          let(:create_params) { { label: "", sort_order: 3 } }

          it "renders the form without creating an item" do
            expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

            expect(response).to have_http_status(:ok)
          end
        end

        context "with project items among the siblings" do
          let!(:chewie) { create(:hierarchy_item, parent: root, label: "Chewie", project: create(:project)) }

          it "keeps the new item before the project items" do
            create_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han Ben Chewie])
            expect(labels_by_position).to eq(%w[Luke Mara Leia Han Ben Chewie])
          end

          context "with a requested position within the project items" do
            let(:create_params) { { label: "Ben", sort_order: chewie.sort_order + 1 } }

            it "keeps the new item before the project items" do
              create_request

              expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han Ben Chewie])
            end
          end

          context "with the label of a project item" do
            let(:create_params) { { label: "chewie", sort_order: 4 } }

            it "renders the form with an error" do
              expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

              expect(response.body).to include("must be unique within the same hierarchy level")
            end
          end
        end
      end

      describe "PATCH update" do
        let(:update_params) { { label: "Luke Skywalker", short: "SKY" } }

        subject(:update_request) { patch "#{items_path}/#{luke.id}", params: update_params, headers: turbo_stream_headers }

        it "updates the item and redirects to its parent" do
          update_request

          expect(luke.reload).to have_attributes(label: "Luke Skywalker", short: "SKY", sort_order: 0)
          expect(response).to redirect_to("#{items_path}/#{root.id}")
          expect(response).to have_http_status(:see_other)
        end

        context "when only changing the case of its own label" do
          let(:update_params) { { label: "LUKE", short: "LS" } }

          it "updates the item" do
            update_request

            expect(luke.reload.label).to eq("LUKE")
          end
        end

        context "with a label used by a sibling in a different case" do
          let(:update_params) { { label: "leia", short: "LS" } }

          it "renders the item form with an error" do
            update_request

            expect(luke.reload.label).to eq("Luke")
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "with a short used by a sibling in a different case" do
          let(:update_params) { { label: "Luke", short: "lo" } }

          it "renders the item form with an error" do
            update_request

            expect(luke.reload.short).to eq("LS")
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "without a label" do
          let(:update_params) { { label: "", short: "LS" } }

          it "keeps the item unchanged" do
            update_request

            expect(luke.reload.label).to eq("Luke")
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          end
        end

        context "for the root item" do
          subject(:update_request) { patch "#{items_path}/#{root.id}", params: update_params, headers: turbo_stream_headers }

          it "keeps the root unchanged", pending: "rendering the error form fails on the missing parent of the root" do
            update_request

            expect(root.reload.label).to be_nil
          end
        end
      end

      describe "POST move" do
        let(:moved_item) { han }
        let(:new_sort_order) { 0 }

        subject(:move_request) { post "#{items_path}/#{moved_item.id}/move", params: { new_sort_order: } }

        it "moves the item before the sibling at the position and redirects to the parent" do
          move_request

          expect(root.reload.children.pluck(:label)).to eq(%w[Han Luke Leia])
          expect(response).to redirect_to("#{items_path}/#{root.id}")
          expect(response).to have_http_status(:see_other)
        end

        it "updates the position cache of the whole tree" do
          move_request

          expect(labels_by_position).to eq(%w[Han Luke Mara Leia])
        end

        context "when moving down" do
          let(:moved_item) { luke }
          let(:new_sort_order) { 2 }

          it "moves the item before the sibling at the position" do
            move_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Leia Luke Han])
            expect(labels_by_position).to eq(%w[Leia Luke Mara Han])
          end
        end

        context "with a position after the last sibling" do
          let(:moved_item) { luke }
          let(:new_sort_order) { 99 }

          it "moves the item to the end" do
            move_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Leia Han Luke])
          end
        end

        context "with a negative position" do
          let(:new_sort_order) { -5 }

          it "moves the item to the start" do
            move_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Han Luke Leia])
          end
        end

        context "with the current position" do
          let(:new_sort_order) { 2 }

          it "keeps the order" do
            move_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han])
            expect(response).to have_http_status(:see_other)
          end
        end

        context "for an item without siblings" do
          let(:moved_item) { mara }

          it "keeps the item in place" do
            move_request

            expect(mara.reload).to have_attributes(parent: luke, sort_order: 0)
            expect(response).to redirect_to("#{items_path}/#{luke.id}")
          end
        end

        context "without a position" do
          subject(:move_request) { post "#{items_path}/#{moved_item.id}/move" }

          it "responds with bad request" do
            move_request

            expect(response).to have_http_status(:bad_request)
            expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han])
          end
        end
      end

      describe "POST change_parent" do
        let(:moved_item) { han }
        let(:new_parent) { luke }
        let(:new_parent_input) { [{ value: new_parent.id }.to_json] }

        subject(:change_parent_request) do
          post "#{items_path}/#{moved_item.id}/change_parent",
               params: { custom_field_hierarchy_forms_new_parent_form_model: { new_parent: new_parent_input } },
               headers: turbo_stream_headers
        end

        it "appends the item to the new parent and redirects to it" do
          change_parent_request

          expect(luke.reload.children.pluck(:label)).to eq(%w[Mara Han])
          expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia])
          expect(URI(response.location).path).to eq("#{items_path}/#{luke.id}")
          expect(response).to have_http_status(:see_other)
        end

        it "updates the position cache of the whole tree" do
          change_parent_request

          expect(labels_by_position).to eq(%w[Luke Mara Han Leia])
        end

        context "when moving an item with descendants" do
          let(:moved_item) { luke }
          let(:new_parent) { leia }

          it "moves the descendants along" do
            change_parent_request

            expect(leia.reload.children.pluck(:label)).to eq(%w[Luke])
            expect(mara.reload.parent).to eq(luke)
            expect(mara.ancestors).to include(leia)
            expect(labels_by_position).to eq(%w[Leia Luke Mara Han])
          end
        end

        context "when moving to the root" do
          let(:moved_item) { mara }
          let(:new_parent) { root }

          it "appends the item to the top level", pending: "the moved item keeps its previous sort order" do
            change_parent_request

            expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han Mara])
            expect(URI(response.location).path).to eq("#{items_path}/#{root.id}")
          end
        end

        context "when a child of the new parent uses the label in a different case" do
          let(:moved_item) { mara }
          let(:new_parent) { leia }

          before { create(:hierarchy_item, parent: leia, label: "MARA") }

          it "keeps the item in place and shows an error" do
            change_parent_request

            expect(mara.reload.parent).to eq(luke)
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "when a child of the new parent uses the short in a different case" do
          let(:moved_item) { mara }
          let(:new_parent) { leia }

          before { create(:hierarchy_item, parent: leia, label: "Ben", short: "mj") }

          it "keeps the item in place and shows an error" do
            change_parent_request

            expect(mara.reload.parent).to eq(luke)
            expect(response.body).to include("must be unique within the same hierarchy level")
          end
        end

        context "with a parent of another custom field" do
          let(:new_parent) { foreign_item }

          it "keeps the item in place", pending: "the new parent is not scoped to the custom field" do
            change_parent_request

            expect(han.reload.parent).to eq(root)
            expect(foreign_item.reload.children).to be_empty
          end
        end

        context "with an unknown parent" do
          let(:new_parent_input) { [{ value: 0 }.to_json] }

          it "keeps the item in place and shows an error" do
            change_parent_request

            expect(han.reload.parent).to eq(root)
            expect(response.body).to include(I18n.t(:notice_parent_item_not_found))
          end
        end

        context "with more than one parent" do
          let(:new_parent_input) { [{ value: luke.id }.to_json, { value: leia.id }.to_json] }

          it "keeps the item in place and shows an error" do
            change_parent_request

            expect(han.reload.parent).to eq(root)
            expect(response.media_type).to eq("text/vnd.turbo-stream.html")
          end
        end

        context "without a parent" do
          subject(:change_parent_request) do
            post "#{items_path}/#{moved_item.id}/change_parent", headers: turbo_stream_headers
          end

          it "responds with bad request" do
            change_parent_request

            expect(response).to have_http_status(:bad_request)
            expect(han.reload.parent).to eq(root)
          end
        end

        context "with project items" do
          let(:project) { create(:project) }
          let!(:chewie) { create(:hierarchy_item, parent: root, label: "Chewie", project:) }

          context "when moving a global item to a parent with project children" do
            let(:moved_item) { mara }
            let(:new_parent) { root }

            it "keeps the item before the project items" do
              change_parent_request

              expect(root.reload.children.pluck(:label)).to eq(%w[Luke Leia Han Mara Chewie])
              expect(labels_by_position).to eq(%w[Luke Leia Han Mara Chewie])
            end
          end

          context "when moving a global item below a project item" do
            let(:new_parent) { chewie }

            it "keeps the item in place and shows an error" do
              change_parent_request

              expect(han.reload.parent).to eq(root)
              expect(response.body).to include("must be a global value or belong to the same project")
            end
          end

          context "when moving a project item below an item of the same project" do
            let(:moved_item) { create(:hierarchy_item, parent: root, label: "Porg", project:) }
            let(:new_parent) { chewie }

            it "moves the item" do
              change_parent_request

              expect(moved_item.reload.parent).to eq(chewie)
            end
          end

          context "when moving a project item below an item of another project" do
            let(:moved_item) { chewie }
            let(:new_parent) { create(:hierarchy_item, parent: root, label: "Jabba", project: create(:project)) }

            it "keeps the item in place and shows an error" do
              change_parent_request

              expect(chewie.reload.parent).to eq(root)
              expect(response.body).to include("must be a global value or belong to the same project")
            end
          end

          context "when moving a project item next to another project's item with the same label" do
            let(:moved_item) { chewie }
            let(:new_parent) { leia }

            before { create(:hierarchy_item, parent: leia, label: "CHEWIE", project: create(:project)) }

            it "moves the item" do
              change_parent_request

              expect(chewie.reload.parent).to eq(leia)
            end
          end

          context "when moving a project item next to a global item with the same label" do
            let(:moved_item) { chewie }
            let(:new_parent) { leia }

            before { create(:hierarchy_item, parent: leia, label: "CHEWIE") }

            it "keeps the item in place and shows an error" do
              change_parent_request

              expect(chewie.reload.parent).to eq(root)
              expect(response.body).to include("must be unique within the same hierarchy level")
            end
          end
        end
      end

      describe "DELETE destroy" do
        let(:deleted_item) { luke }

        subject(:destroy_request) { delete "#{items_path}/#{deleted_item.id}", headers: turbo_stream_headers }

        it "deletes the item with its descendants" do
          expect { destroy_request }.to change(CustomField::Hierarchy::Item, :count).by(-2)

          expect(root.reload.children.pluck(:label)).to eq(%w[Leia Han])
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "closes the gap in the sort order of the siblings" do
          destroy_request

          expect(leia.reload.sort_order).to eq(0)
          expect(han.reload.sort_order).to eq(1)
        end

        context "for the root item" do
          let(:deleted_item) { root }

          it "keeps the tree", pending: "the controller calls full_messages on the failure symbol" do
            expect { destroy_request }.not_to change(CustomField::Hierarchy::Item, :count)
          end
        end

        context "for an unknown item" do
          subject(:destroy_request) { delete "#{items_path}/0", headers: turbo_stream_headers }

          it "responds with not found" do
            expect { destroy_request }.not_to change(CustomField::Hierarchy::Item, :count)

            expect(response).to have_http_status(:not_found)
          end
        end
      end

      describe "with an item of another custom field", pending: "the active item is not scoped to the custom field" do
        it "does not show the item" do
          get "#{items_path}/#{foreign_item.id}"

          expect(response).to have_http_status(:not_found)
        end

        it "does not render the edit form" do
          get "#{items_path}/#{foreign_item.id}/edit"

          expect(response).to have_http_status(:not_found)
        end

        it "does not create a child" do
          expect do
            post "#{items_path}/#{foreign_item.id}/new_child", params: { label: "Ben", sort_order: 0 }
          end.not_to change(CustomField::Hierarchy::Item, :count)

          expect(response).to have_http_status(:not_found)
        end

        it "does not update the item" do
          patch "#{items_path}/#{foreign_item.id}", params: { label: "Anakin", short: "DV" }

          expect(response).to have_http_status(:not_found)
          expect(foreign_item.reload.label).to eq("Vader")
        end

        it "does not reorder the item" do
          post "#{items_path}/#{foreign_item.id}/move", params: { new_sort_order: 5 }

          expect(response).to have_http_status(:not_found)
          expect(foreign_item.reload.sort_order).to eq(0)
        end

        it "does not change the parent of the item" do
          post "#{items_path}/#{foreign_item.id}/change_parent",
               params: { custom_field_hierarchy_forms_new_parent_form_model: { new_parent: [{ value: luke.id }.to_json] } }

          expect(response).to have_http_status(:not_found)
          expect(foreign_item.reload.parent).to eq(other_custom_field.hierarchy_root)
        end

        it "does not delete the item" do
          expect { delete "#{items_path}/#{foreign_item.id}" }.not_to change(CustomField::Hierarchy::Item, :count)

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  shared_examples "managing weighted items" do
    let!(:one) { create(:hierarchy_item, parent: root, label: "One", weight: 1) }
    let!(:two) { create(:hierarchy_item, parent: root, label: "Two", weight: 2) }

    before { login_as admin }

    describe "POST create" do
      let(:create_params) { { label: "Three", weight: "3.5", sort_order: 2 } }

      subject(:create_request) { post items_path, params: create_params }

      it "creates the item with its weight" do
        expect { create_request }.to change(CustomField::Hierarchy::Item, :count).by(1)

        expect(root.reload.children.last).to have_attributes(label: "Three", weight: 3.5)
        expect(response).to redirect_to("#{items_path}/new?position=3")
      end

      context "without a weight" do
        let(:create_params) { { label: "Three", sort_order: 2 } }

        it "renders the form without creating an item" do
          expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

          expect(response).to have_http_status(:ok)
        end
      end

      context "with a non-numeric weight" do
        let(:create_params) { { label: "Three", weight: "heavy", sort_order: 2 } }

        it "renders the form without creating an item" do
          expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

          expect(response).to have_http_status(:ok)
        end
      end

      context "with a label used by a sibling in a different case" do
        let(:create_params) { { label: "two", weight: "3", sort_order: 2 } }

        it "renders the form with an error" do
          expect { create_request }.not_to change(CustomField::Hierarchy::Item, :count)

          expect(response.body).to include("must be unique within the same hierarchy level")
        end
      end
    end

    describe "PATCH update" do
      let(:update_params) { { label: "Uno", weight: "42" } }

      subject(:update_request) { patch "#{items_path}/#{one.id}", params: update_params, headers: turbo_stream_headers }

      it "updates the label and the weight" do
        update_request

        expect(one.reload).to have_attributes(label: "Uno", weight: 42)
        expect(response).to have_http_status(:see_other)
      end

      context "without a weight" do
        let(:update_params) { { label: "Uno", weight: "" } }

        it "keeps the item unchanged" do
          update_request

          expect(one.reload).to have_attributes(label: "One", weight: 1)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end
    end
  end

  context "for a work package custom field", with_ee: %i[custom_field_hierarchies weighted_item_lists] do
    let(:items_path) { "/admin/settings/work_package_custom_fields/#{custom_field.id}/items" }

    context "with a hierarchy" do
      let(:custom_field) { create(:hierarchy_wp_custom_field) }

      it_behaves_like "managing hierarchy items"
    end

    context "with a weighted item list" do
      let(:custom_field) { create(:weighted_item_list_wp_custom_field) }

      it_behaves_like "managing weighted items"
    end

    context "when deleting an item assigned to work packages" do
      let(:wp_type) { create(:type_task) }
      let(:project) { create(:project, types: [wp_type]) }
      let(:custom_field) { create(:hierarchy_wp_custom_field, types: [wp_type]) }
      let!(:luke) { create(:hierarchy_item, parent: root, label: "Luke") }
      let!(:mara) { create(:hierarchy_item, parent: luke, label: "Mara") }
      let!(:leia) { create(:hierarchy_item, parent: root, label: "Leia") }
      let(:work_package_with_item) { create(:work_package, project:, type: wp_type) }
      let(:work_package_with_child) { create(:work_package, project:, type: wp_type) }
      let(:work_package_with_other_item) { create(:work_package, project:, type: wp_type) }

      before do
        create(:work_package_custom_value, custom_field:, customized: work_package_with_item, value: luke.id)
        create(:work_package_custom_value, custom_field:, customized: work_package_with_child, value: mara.id)
        create(:work_package_custom_value, custom_field:, customized: work_package_with_other_item, value: leia.id)

        login_as admin
        delete "#{items_path}/#{luke.id}", headers: turbo_stream_headers
      end

      it "removes the values of the item and its descendants" do
        expect(work_package_with_item.reload.custom_value_for(custom_field).value).to be_nil
        expect(work_package_with_child.reload.custom_value_for(custom_field).value).to be_nil
      end

      it "keeps the values of other items" do
        expect(work_package_with_other_item.reload.custom_value_for(custom_field).value).to eq(leia.id.to_s)
      end
    end
  end

  context "for a project custom field", with_ee: %i[custom_field_hierarchies weighted_item_lists] do
    let(:items_path) { "/admin/settings/project_custom_fields/#{custom_field.id}/items" }

    context "with a hierarchy" do
      let(:custom_field) { create(:hierarchy_project_custom_field) }

      it_behaves_like "managing hierarchy items"
    end

    context "with a weighted item list" do
      let(:custom_field) { create(:weighted_item_list_project_custom_field) }

      it_behaves_like "managing weighted items"
    end

    context "with a weighted item list used by calculated values", with_ee: %i[calculated_values weighted_item_lists] do
      let(:project_using_one) { create(:project) }
      let(:project_using_two) { create(:project) }
      let(:custom_field) do
        create(:weighted_item_list_project_custom_field, projects: [project_using_one, project_using_two])
      end
      let!(:one) { create(:hierarchy_item, parent: root, label: "One", weight: 1) }
      let!(:two) { create(:hierarchy_item, parent: root, label: "Two", weight: 2) }
      let!(:calculated_value) do
        create(:calculated_value_project_custom_field,
               :skip_validations,
               projects: [project_using_one, project_using_two],
               formula: "{{cf_#{custom_field.id}}} * 2")
      end

      before do
        project_using_one.custom_values.create!(custom_field:, value: one.id)
        project_using_one.custom_values.create!(custom_field: calculated_value, value: "123")
        project_using_two.custom_values.create!(custom_field:, value: two.id)
        project_using_two.custom_values.create!(custom_field: calculated_value, value: "123")

        login_as admin
      end

      context "when updating the weight of an item" do
        before { patch "#{items_path}/#{one.id}", params: { label: "One", weight: "42" }, headers: turbo_stream_headers }

        it "recalculates the values using the item" do
          expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: "84.0")
        end

        it "keeps the values using other items" do
          expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
        end
      end

      context "when deleting an item" do
        before { delete "#{items_path}/#{one.id}", headers: turbo_stream_headers }

        it "recalculates the values using the item" do
          expect(project_using_one.custom_value_for(calculated_value)).to have_attributes(value: nil)
        end

        it "keeps the values using other items" do
          expect(project_using_two.custom_value_for(calculated_value)).to have_attributes(value: "123")
        end
      end
    end
  end

  context "for a user custom field", with_ee: %i[custom_field_hierarchies] do
    let(:items_path) { "/admin/settings/user_custom_fields/#{custom_field.id}/items" }
    let(:custom_field) { create(:user_custom_field, :hierarchy) }

    it_behaves_like "managing hierarchy items"
  end
end
