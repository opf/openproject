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

RSpec.describe "Move dialog asking whether descendants should follow", :js do
  let(:mover_role) do
    create(:project_role, permissions: %i[view_work_packages move_work_packages add_work_packages])
  end
  let(:mover) { create(:user, member_with_roles: { source => mover_role }) }

  let(:type) { create(:type, name: "Bug") }
  let!(:source) { create(:project, name: "Source", types: [type]) }

  let(:work_package) { create(:work_package, project: source, type:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(source) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:move_dialog) { Components::WorkPackages::MoveDialog.new }

  before do
    work_package
    login_as mover
    wp_table.visit!
    expect_angular_frontend_initialized
  end

  context "when the work package has no descendants" do
    it "skips the dialog and goes straight to the move form" do
      context_menu.open_for work_package
      context_menu.choose "Move to another project"

      find_by_id("new_project_id")
      expect(page).to have_no_css(move_dialog.dialog_css_selector)
    end
  end

  context "when the work package has a descendant the user may move" do
    let!(:child) { create(:work_package, project: source, parent: work_package, type:) }

    it "shows the descendants choice, with 'move just this work package' preselected" do
      context_menu.open_for work_package
      context_menu.choose "Move to another project"

      move_dialog.expect_open
      move_dialog.expect_descendants_choice
      move_dialog.expect_no_permission_banner
    end

    it "shows the permission banner only once 'Include all descendants' is picked" do
      context_menu.open_for work_package
      context_menu.choose "Move to another project"

      move_dialog.expect_open
      move_dialog.expect_no_permission_banner

      move_dialog.within_dialog do
        choose I18n.t("work_packages.move_dialog_shared.descendants_choice.with_descendants_label"), allow_label_click: true
      end
      move_dialog.expect_permission_banner
    end
  end

  context "when the work package has a descendant and cross-project relations are disabled",
          with_settings: { cross_project_work_package_relations: false } do
    let!(:child) { create(:work_package, project: source, parent: work_package, type:) }

    it "shows the dialog with 'move just this work package' disabled and the info banner already visible" do
      context_menu.open_for work_package
      context_menu.choose "Move to another project"

      move_dialog.expect_open
      move_dialog.expect_descendants_choice

      move_dialog.within_dialog do
        expect(page).to have_field(
          I18n.t("work_packages.move_dialog.descendants_choice.self_only_label"), disabled: true
        )
        expect(page).to have_checked_field(
          I18n.t("work_packages.move_dialog_shared.descendants_choice.with_descendants_label"), visible: :all
        )
        expect(page).to have_text(I18n.t("work_packages.move_dialog_shared.same_project_required_notice"))
      end
    end
  end
end
