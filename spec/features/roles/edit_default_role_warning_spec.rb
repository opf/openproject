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

RSpec.describe "Editing a project role" do
  let!(:admin) { create(:admin) }
  let!(:default_role) { create(:project_creator_role) }
  let!(:other_role) { create(:project_creator_role, name: "Other creator role") }

  before do
    login_as admin
  end

  context "when the role is configured as the default role for new projects" do
    before do
      allow(Setting).to receive(:new_project_user_role_id).and_return(default_role.id.to_s)
    end

    it "shows a warning banner listing the required permissions" do
      visit edit_role_path(default_role)

      expect(page).to have_text("default role given to non-admin users who create a project")
      ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR.each do |permission|
        expect(page).to have_css("ul li", text: I18n.t("permission_#{permission}"))
      end
    end

    it "does not show the warning when editing a different role" do
      visit edit_role_path(other_role)

      expect(page).to have_button("Save")
      expect(page).to have_no_text("default role given to non-admin users who create a project")
    end
  end

  context "when no default role is configured" do
    before do
      allow(Setting).to receive(:new_project_user_role_id).and_return("")
    end

    it "does not show the warning" do
      visit edit_role_path(default_role)

      expect(page).to have_button("Save")
      expect(page).to have_no_text("default role given to non-admin users who create a project")
    end
  end
end
