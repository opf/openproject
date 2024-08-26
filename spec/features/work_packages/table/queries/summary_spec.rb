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
require "features/work_packages/work_packages_page"

RSpec.describe "Work package query summary item", :js do
  let(:project) { create(:project, identifier: "test_project", public: false) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:work_package) { create(:work_package, project:) }
  let(:wp_page) { Pages::WorkPackagesTable.new project }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end

  before do
    login_as(current_user)
    wp_page.visit!
  end

  it "allows users to visit the summary page" do
    find(".op-submenu--item-action", text: "Summary", wait: 10).click
    expect(page).to have_css("h2", text: "Summary")
    expect(page).to have_css("td", text: work_package.type.name)
  end
end
