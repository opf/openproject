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
# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Project settings screen scheme" do # rubocop:disable RSpec/DescribeClass
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [type]) }

  shared_let(:scheme) do
    screen = create(:create_screen, name: "Bug create")
    section = create(:screen_section, screen:, name: "General")
    create(:screen_item, screen:, section:, field_key: "subject")
    scheme = create(:screen_scheme, name: "Dev")
    create(:screen_scheme_item, scheme:, type:, create_screen: screen)
    scheme
  end

  context "with the assign permission" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages assign_screen_scheme] }) }

    it "assigns a scheme and shows the effective layout" do
      visit project_settings_screen_scheme_path(project)
      select "Dev", from: "scheme_id"
      click_button "Save"

      expect(page).to have_text("Successful update.")
      expect(ProjectScreenScheme.find_by(project_id: project.id).scheme).to eq(scheme)
      expect(page).to have_text("Effective layout")
      expect(page).to have_text("Bug")

      select "Native layout", from: "scheme_id"
      click_button "Save"
      expect(ProjectScreenScheme.where(project_id: project.id)).to be_empty
    end
  end

  context "without the permission" do
    current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    it "is forbidden" do
      visit project_settings_screen_scheme_path(project)
      expect(page).to have_text("You are not authorized")
    end
  end
end
