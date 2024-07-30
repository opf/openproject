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

require_relative "../../spec_helper"

RSpec.describe "BIM Revit Add-in navigation spec", :js,
               driver: :chrome_revit_add_in, with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }
  let!(:work_package) { create(:work_package, project:) }
  let(:role) do
    create(:project_role,
           permissions: %i[view_ifc_models manage_ifc_models add_work_packages edit_work_packages view_work_packages])
  end
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end

  let(:model_page) { Pages::IfcModels::ShowDefault.new(project) }

  before do
    login_as(user)
    model_page.visit!
  end

  it "click on refresh button reloads information" do
    # Context BCF cards view
    model_page.page_shows_a_filter_button(true)
    work_package.update_attribute(:subject, "Refreshed while in cards view")
    model_page.click_refresh_button
    expect(page).to have_text("Refreshed while in cards view")

    # Context BCF full view
    model_page.click_info_icon(work_package)
    work_package.update_attribute(:subject, "Refreshed while in full view")
    model_page.click_refresh_button
    expect(page).to have_text("Refreshed while in full view")
  end
end
