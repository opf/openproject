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

RSpec.describe WorkPackages::BulkDeleteDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:user) { create(:admin) }

  let(:main_project) { create(:project, name: "Main Project") }
  let(:sub_project) { create(:project, name: "Sub Project", parent: main_project) }

  let(:wp_main) { create(:work_package, project: main_project) }
  let(:work_packages) { [wp_main] }

  subject(:component) { described_class.new(work_packages:) }

  def t(key, **)
    I18n.t("work_packages.bulk_delete_dialog.#{key}", **)
  end

  before do
    User.current = user
  end

  describe "#projects" do
    context "when all work packages belong to the same project and have no descendants" do
      it "returns only that project" do
        expect(component.send(:projects)).to eq([main_project])
      end
    end
  end

  describe "#description" do
    context "when work packages have no descendants" do
      it "returns the description without children mention" do
        expect(component.send(:description)).to eq(
          I18n.t("work_packages.bulk_delete_dialog.description")
        )
      end
    end

    context "when work packages have descendants" do
      let(:child_wp) { create(:work_package, project: main_project, parent: wp_main) }

      before { child_wp }

      it "asks whether to also delete the descendants" do
        expect(component.send(:description)).to eq(
          I18n.t("work_packages.bulk_delete_dialog.descendants_choice.question")
        )
      end
    end
  end

  describe "the descendants choice" do
    subject do
      render_inline(component)
      page
    end

    context "with descendants" do
      let(:child_wp) { create(:work_package, project: main_project, parent: wp_main, subject: "Child wp") }

      before { child_wp }

      it "asks whether to delete the descendants too" do
        expect(subject).to have_text t("descendants_choice.question")
      end

      it "offers both choices, defaulting to deleting the descendants" do
        expect(subject).to have_text t("descendants_choice.self_only_label")
        expect(subject).to have_checked_field(t("descendants_choice.with_descendants_label"), visible: :all)
      end

      it "does not preview the descendants or ask to confirm them yet" do
        expect(subject).to have_no_text "Child wp"
        expect(subject).to have_no_text t("confirm_deletion")
      end
    end

    context "when the selected work packages span multiple projects" do
      let(:descendant_project) { create(:project, name: "Descendant Project") }
      let(:wp_other) { create(:work_package, project: sub_project) }
      let(:work_packages) { [wp_main, wp_other] }

      before do
        create(:work_package, parent: wp_main, project: descendant_project, subject: "Deep child")
      end

      it "warns that the roots span multiple projects, linking each root's project but not the descendants'" do
        expect(subject).to have_text t("cross_project_warning_html",
                                       projects: "#{main_project.name}, #{sub_project.name}")
        expect(subject).to have_link main_project.name, href: project_path(main_project)
        expect(subject).to have_link sub_project.name, href: project_path(sub_project)
        expect(subject).to have_no_link "Descendant Project"
      end
    end
  end

  describe "the no-descendants dialog" do
    let(:wp_one) { create(:work_package, project: main_project, subject: "First to delete") }
    let(:wp_two) { create(:work_package, project: sub_project, subject: "Second to delete") }
    let(:work_packages) { [wp_one, wp_two] }

    subject do
      render_inline(component)
      page
    end

    it "lists each selected work package and asks to confirm the deletion" do
      expect(subject).to have_text "First to delete"
      expect(subject).to have_text "Second to delete"
      expect(subject).to have_text t("confirm_deletion")
    end

    it "warns when the selection spans multiple projects" do
      expect(subject).to have_text t("cross_project_warning_html",
                                     projects: "#{main_project.name}, #{sub_project.name}")
      expect(subject).to have_link main_project.name, href: project_path(main_project)
    end
  end
end
