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

RSpec.describe "version delete", :js, :with_cuprite do
  let!(:project) { create(:project, name: "Parent") }
  let!(:archived_child) { create(:project, name: "Archived child", parent: project, active: false) }

  let!(:user) do
    create(:user,
           member_with_permissions: { version.project => %i[manage_versions view_work_packages] })
  end
  let!(:version) { create(:version, sharing: "system") }
  let!(:wp_archived) { create(:work_package, version:, project: archived_child, subject: "Task in archive") }

  before do
    login_as(user)
  end

  it "cannot delete a version in use in archived projects, but shows details where it is used" do
    # from the version show page
    visit version_path(version)

    within ".toolbar" do
      accept_confirm do
        click_link "Delete"
      end
    end

    expect(page).to have_css(".op-toast.-error", text: I18n.t(:error_can_not_delete_in_use_archived_undisclosed))
    expect(page).to have_no_css("a", text: "Archived child")

    user.update!(admin: true)

    # from the version show page
    visit version_path(version)

    within ".toolbar" do
      accept_confirm do
        click_link "Delete"
      end
    end

    expect(page).to have_css(".op-toast.-error", text: "There are also work packages in archived projects.")
    expect(page).to have_css("a", text: "Archived child")
  end
end
