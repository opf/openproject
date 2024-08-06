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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

RSpec.describe "Deleting time entries", :js do
  let(:project) { work_package.project }
  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           delete_work_packages
                           edit_cost_entries
                           view_cost_entries])
  end
  let(:work_package) { create(:work_package) }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }
  let(:cost_type) do
    type = create(:cost_type, name: "Translations")
    create(:cost_rate,
           cost_type: type,
           rate: 7.00)
    type
  end
  let(:budget) do
    create(:budget, project:)
  end
  let(:other_work_package) { create(:work_package, project:, budget:) }
  let(:cost_entry) do
    create(:cost_entry,
           work_package:,
           project:,
           units: 2.00,
           cost_type:,
           user:)
  end

  it "allows to move the time entry to a different work package" do
    login_as(user)

    work_package
    other_work_package
    cost_entry

    wp_page = Pages::FullWorkPackage.new(work_package)
    wp_page.visit!

    SeleniumHubWaiter.wait
    find_by_id("action-show-more-dropdown-menu").click

    click_link(I18n.t("js.button_delete"))

    destroy_modal.expect_listed(work_package)
    destroy_modal.confirm_deletion

    SeleniumHubWaiter.wait
    choose "to_do_action_reassign"
    fill_in "to_do_reassign_to_id", with: other_work_package.id

    click_button(I18n.t("button_delete"))

    table = Pages::WorkPackagesTable.new(project)
    table.expect_current_path

    other_wp_page = Pages::FullWorkPackage.new(other_work_package)
    other_wp_page.visit!

    wp_page.expect_attributes costs_by_type: "2 Translations"
  end
end
