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

# Second step of the bulk delete flow: shown after the user chose to delete descendants.
# It owns the deletion preview (and the descendant-inclusive counts/projects) that
# BulkDeleteDialogComponent used to render, so these examples were migrated from
# bulk_delete_dialog_component_spec unchanged.
RSpec.describe WorkPackages::BulkDeleteDescendantsDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:admin) }

  let(:main_project) { create(:project, name: "Main Project") }
  let(:sub_project) { create(:project, name: "Sub Project", parent: main_project) }
  let(:sub_sub_project) { create(:project, name: "Sub Sub Project", parent: sub_project) }

  let(:wp_main) { create(:work_package, project: main_project) }
  let(:work_packages) { [wp_main] }

  subject(:component) { described_class.new(work_packages:) }

  before do
    User.current = user
  end

  describe "#projects" do
    context "when work packages have descendants in sub-projects" do
      let(:child_wp) { create(:work_package, project: sub_project, parent: wp_main) }
      let(:grandchild_wp) { create(:work_package, project: sub_sub_project, parent: child_wp) }

      before do
        grandchild_wp # ensure all records are created
      end

      it "includes projects from descendants" do
        projects = component.send(:projects)

        expect(projects).to include(main_project, sub_project, sub_sub_project)
      end

      it "reports multiple projects" do
        expect(component.send(:multiple_projects?)).to be true
      end

      it "links every project name" do
        render_inline(component)

        [main_project, sub_project, sub_sub_project].each do |project|
          expect(page).to have_link project.name, href: project_path(project)
        end
      end
    end
  end

  describe "descendants the user may not delete" do
    shared_let(:permitted_project) { create(:project, name: "Permitted Project") }
    shared_let(:view_only_project) { create(:project, name: "View Only Project") }
    shared_let(:invisible_project) { create(:project, name: "Invisible Project") }

    let(:permitted_permissions) { %i[view_work_packages delete_work_packages] }
    let(:permitted_user) do
      create(:user,
             member_with_permissions: {
               permitted_project => permitted_permissions,
               view_only_project => %i[view_work_packages]
             })
    end

    shared_let(:parent_wp) { create(:work_package, project: permitted_project, subject: "Parent to delete") }

    subject do
      render_inline(described_class.new(work_packages: [parent_wp]))
      page
    end

    before do
      login_as(permitted_user)
    end

    def t(key, **)
      I18n.t("work_packages.bulk_delete_dialog.#{key}", **)
    end

    context "with a child in an invisible project" do
      shared_let(:invisible_child) do
        create(:work_package, project: invisible_project, parent: parent_wp, subject: "Secret child")
      end

      it "does not disclose the invisible work package or its project" do
        expect(subject).to have_no_text "Secret child"
        expect(subject).to have_no_text "Invisible Project"
      end

      it "asks about the selection alone, since nothing else gets deleted" do
        expect(subject).to have_text t("description")
        expect(subject).to have_text t("hidden_descendants_only_warning", count: 1)
        expect(subject).to have_no_text t("hidden_descendants_warning", count: 1)
      end

      it "does not claim the deletion spans multiple projects" do
        expect(subject).to have_no_text "span multiple projects"
      end

      it "does not claim descendants will be deleted" do
        expect(subject).to have_no_text t("children_label")
        expect(subject).to have_text t("confirm_deletion")
      end
    end

    context "with a visible child the user may not delete" do
      shared_let(:view_only_child) do
        create(:work_package, project: view_only_project, parent: parent_wp, subject: "View only child")
      end

      it "does not offer to delete it" do
        expect(subject).to have_no_text t("children_label")
      end

      it "warns that it is preserved and links its project" do
        expect(subject).to have_text t("description")
        expect(subject).to have_text t("undeletable_descendants_warning_html",
                                       count: 1,
                                       projects: view_only_project.name)
        expect(subject).to have_link view_only_project.name, href: project_path(view_only_project)
      end

      it "counts only the selection" do
        expect(subject).to have_text t("heading", count: 1)
      end
    end

    context "with a grandchild in an invisible project" do
      shared_let(:visible_child) do
        create(:work_package, project: permitted_project, parent: parent_wp, subject: "Visible child")
      end
      shared_let(:invisible_grandchild) do
        create(:work_package, project: invisible_project, parent: visible_child, subject: "Secret grandchild")
      end

      it "lists only the descendant it deletes" do
        expect(subject).to have_text "Visible child"
        expect(subject).to have_no_text "Secret grandchild"
        expect(subject).to have_no_text "Invisible Project"
      end

      it "warns about the grandchild it cannot see" do
        expect(subject).to have_text t("hidden_descendants_warning", count: 1)
      end
    end

    context "with one child hidden and another visible but undeletable" do
      shared_let(:view_only_child) do
        create(:work_package, project: view_only_project, parent: parent_wp, subject: "View only child")
      end
      shared_let(:invisible_child) do
        create(:work_package, project: invisible_project, parent: parent_wp, subject: "Secret child")
      end

      it "uses the permission wording and folds the hidden one into the count" do
        expect(subject).to have_text t("undeletable_descendants_warning", count: 2)
        expect(subject).to have_no_text t("hidden_descendants_warning", count: 1)
      end

      it "names no project, since the count covers one it cannot show" do
        expect(subject).to have_no_text "Invisible Project"
        expect(subject).to have_no_link view_only_project.name
      end
    end
  end

  describe "#total_count" do
    context "when a selected work package is itself a descendant of another selection" do
      let(:child_wp) { create(:work_package, project: main_project, parent: wp_main) }
      let(:grandchild_wp) { create(:work_package, project: main_project, parent: child_wp) }
      let(:work_packages) { [wp_main, child_wp] }

      before do
        grandchild_wp
      end

      it "counts every affected work package once" do
        expect(component.send(:total_count)).to eq(3)
      end
    end

    context "with a descendant the user may not delete" do
      let(:restricted_project) { create(:project, name: "Restricted Project") }
      let(:restricted_user) do
        create(:user,
               member_with_permissions: {
                 main_project => %i[view_work_packages delete_work_packages]
               })
      end
      let(:selected_wp) { create(:work_package, project: main_project) }
      let(:deleted_child) { create(:work_package, project: main_project, parent: selected_wp) }
      let(:unlinked_child) { create(:work_package, project: restricted_project, parent: selected_wp) }

      let(:work_packages) { [selected_wp] }

      before do
        deleted_child
        unlinked_child
        login_as(restricted_user)
      end

      it "counts only the selection and the descendants it deletes" do
        expect(component.send(:total_count)).to eq(2)
      end

      it "reports the one that is only unlinked separately" do
        expect(component.send(:undeletable_count)).to eq(1)
      end

      it "puts the listed count in the heading" do
        render_inline(component)

        expect(page).to have_text I18n.t("work_packages.bulk_delete_dialog.heading", count: 2)
      end
    end
  end

  describe "#description" do
    context "when work packages have descendants" do
      let(:child_wp) { create(:work_package, project: main_project, parent: wp_main) }

      before do
        child_wp # ensure record is created
      end

      it "returns the description mentioning children" do
        expect(component.send(:description)).to eq(
          I18n.t("work_packages.bulk_delete_dialog.description_with_descendants")
        )
      end
    end
  end
end
