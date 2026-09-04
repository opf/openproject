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

RSpec.describe WorkPackages::DeleteDescendantsDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:home_project) { create(:project, name: "Home project") }
  shared_let(:deletable_project) { create(:project, name: "Deletable project") }
  shared_let(:view_only_project) { create(:project, name: "View only project") }
  shared_let(:invisible_project) { create(:project, name: "Invisible project") }

  let(:home_permissions) { %i[view_work_packages delete_work_packages] }
  let(:user) do
    create(:user,
           member_with_permissions: {
             home_project => home_permissions,
             deletable_project => %i[view_work_packages delete_work_packages],
             view_only_project => %i[view_work_packages]
           })
  end

  shared_let(:work_package) { create(:work_package, project: home_project, subject: "Parent to delete") }

  subject do
    render_inline(described_class.new(work_package:))
    page
  end

  before do
    login_as(user)
  end

  def t(key, **)
    I18n.t("work_packages.delete_dialog.#{key}", **)
  end

  def deletable_child
    create(:work_package, project: deletable_project, parent: work_package, subject: "Deletable child")
  end

  def view_only_child
    create(:work_package, project: view_only_project, parent: work_package, subject: "View only child")
  end

  def invisible_child
    create(:work_package, project: invisible_project, parent: work_package, subject: "Secret child")
  end

  context "with every descendant deletable" do
    before { deletable_child }

    it "asks about the listed descendants and lists them" do
      expect(subject).to have_text t("description", name: work_package.to_s)
      expect(subject).to have_text I18n.t("work_packages.bulk_delete_dialog.children_label")
      expect(subject).to have_text "Deletable child"
      expect(subject).to have_text t("confirm_descendants_deletion")
    end

    it "names the projects it deletes from and links each one" do
      expect(subject).to have_text t("cross_project_warning_html",
                                     projects: "#{home_project.name}, #{deletable_project.name}")
      expect(subject).to have_link home_project.name, href: project_path(home_project)
      expect(subject).to have_link deletable_project.name, href: project_path(deletable_project)
    end

    it "warns about nothing surviving" do
      expect(subject).to have_no_text "will not be deleted"
      expect(subject).to have_no_text "cannot be deleted"
    end
  end

  context "with a deletable descendant and one the user cannot see" do
    before do
      deletable_child
      invisible_child
    end

    it "asks about the work package alone" do
      expect(subject).to have_text t("description", name: work_package.to_s)
    end

    it "leads with what gets deleted, then the hidden one" do
      expect(subject).to have_text t("hidden_descendants_warning", count: 1)
    end

    it "discloses neither the hidden work package nor its project" do
      expect(subject).to have_no_text "Secret child"
      expect(subject).to have_no_text "Invisible project"
    end
  end

  context "with nothing deletable and the only descendant hidden" do
    before { invisible_child }

    it "asks about the work package alone" do
      expect(subject).to have_text t("description", name: work_package.to_s)
      expect(subject).to have_text t("confirm_deletion")
    end

    it "drops the clause about what gets deleted" do
      expect(subject).to have_text t("hidden_descendants_only_warning", count: 1)
      expect(subject).to have_no_text t("hidden_descendants_warning", count: 1)
    end
  end

  context "with a deletable descendant and one the user cannot delete" do
    before do
      deletable_child
      view_only_child
    end

    it "asks about the work package alone" do
      expect(subject).to have_text t("description", name: work_package.to_s)
    end

    it "counts only the preserved one" do
      expect(subject).to have_text t("undeletable_descendants_warning_html",
                                     count: 1,
                                     projects: view_only_project.name)
    end

    it "links the project it cannot delete in" do
      expect(subject).to have_link view_only_project.name, href: project_path(view_only_project)
    end

    it "lists only the descendant it deletes" do
      expect(subject).to have_text "Deletable child"
      expect(subject).to have_no_text "View only child"
    end
  end

  context "with one visible descendant the user cannot delete" do
    before { view_only_child }

    it "asks about the work package alone" do
      expect(subject).to have_text t("description", name: work_package.to_s)
      expect(subject).to have_text t("confirm_deletion")
    end

    it "drops the clause about what gets deleted and still links the project" do
      expect(subject).to have_text t("undeletable_descendants_warning_html",
                                     count: 1,
                                     projects: view_only_project.name)
      expect(subject).to have_link view_only_project.name, href: project_path(view_only_project)
    end

    it "does not offer to delete it" do
      expect(subject).to have_no_text I18n.t("work_packages.bulk_delete_dialog.children_label")
    end
  end

  context "with one preserved descendant visible and another hidden" do
    before do
      deletable_child
      view_only_child
      invisible_child
    end

    it "uses the permission wording and folds the hidden one into the count" do
      expect(subject).to have_text t("undeletable_descendants_warning", count: 2)
    end

    it "names no project, since the count covers one it cannot show" do
      expect(subject).to have_no_text "Invisible project"
      expect(subject).to have_no_link view_only_project.name
    end
  end

  context "with a deletable work package below an undeletable one" do
    before do
      child = view_only_child
      create(:work_package, project: deletable_project, parent: child, subject: "Deletable grandchild")
    end

    it "counts only the survivor and never mentions its subtree" do
      expect(subject).to have_text t("undeletable_descendants_warning_html",
                                     count: 1,
                                     projects: view_only_project.name)
      expect(subject).to have_no_text "Deletable grandchild"
    end
  end
end
