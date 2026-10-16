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

RSpec.describe "Cost report in subproject", :js do
  let!(:project) { create(:project) }
  let!(:subproject) { create(:project, parent: project) }

  let!(:role) { create(:project_role, permissions: %i(view_cost_entries view_own_cost_entries)) }
  let!(:user) do
    create(:user,
           member_with_roles: { subproject => role })
  end

  before do
    login_as(user)
    visit project_path(subproject)
  end

  it "provides filtering" do
    within "#main-menu" do
      click_on "Time and costs"
    end

    within "#content" do
      expect(page).to have_content "New cost report"
    end
  end
end
