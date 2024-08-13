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
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "Update status from WP card", :js, :with_cuprite, with_config: { edition: "bim" } do
  let(:manager_role) do
    create(:project_role, permissions: %i[view_work_packages edit_work_packages view_ifc_models view_linked_issues])
  end
  let(:manager) do
    create(:user,
           firstname: "Manager",
           lastname: "Guy",
           member_with_roles: { project => manager_role })
  end
  let(:status1) { create(:status) }
  let(:status2) { create(:status) }

  let(:type) { create(:type) }
  let!(:project) { create(:project, types: [type], enabled_module_names: %i[bim work_package_tracking]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           subject: "Foobar")
  end

  let!(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: status1,
           new_status: status2,
           role: manager_role)
  end

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:wp_card_view) { Pages::WorkPackageCards.new(project) }

  before do
    login_as(manager)

    wp_table.visit!
    loading_indicator_saveguard
    wp_table.expect_work_package_listed(work_package)

    wp_table.switch_view "Cards"
  end

  it "can update the status through the button" do
    status_button = wp_card_view.status_button(work_package)
    status_button.update status2.name

    wp_card_view.expect_and_dismiss_toaster message: "Successful update."
    status_button.expect_text status2.name

    work_package.reload
    expect(work_package.status).to eq(status2)
  end
end
