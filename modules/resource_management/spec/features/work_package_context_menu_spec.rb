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

RSpec.describe "Allocate resource from the work package context menu", :js, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, project:, subject: "Build the thing") }

  let(:wp_view) { Pages::FullWorkPackage.new(work_package, project) }
  let(:menu_item_label) { I18n.t("js.button_allocate_resource") }

  before do
    login_as(user)
    wp_view.visit!
    find("#action-show-more-dropdown-menu .button").click
  end

  context "with permission to allocate resources" do
    let(:user) do
      create(:user,
             member_with_permissions: { project => %i[view_work_packages view_resource_planners allocate_user_resources] })
    end

    it "opens the allocation dialog with the work package preselected" do
      find(".menu-item", text: menu_item_label).click

      within_dialog do
        expect(page).to have_text(I18n.t("resource_management.allocate_resource_dialog.title"))
        expect(page).to have_text(work_package.subject)
      end
    end
  end

  context "without permission to allocate resources" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages view_resource_planners] })
    end

    it "does not offer the menu item" do
      expect(page).to have_css(".menu-item")
      expect(page).to have_no_css(".menu-item", text: menu_item_label)
    end
  end
end
