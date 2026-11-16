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

RSpec.describe "Backlogs project module dependencies", :js do
  let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  let(:modules_settings_page) { Pages::Projects::Settings::Modules.new(project) }

  current_user do
    create(:user, member_with_permissions: { project => %i[edit_project select_project_modules] })
  end

  it "requires Boards to be enabled alongside Backlogs" do
    modules_settings_page.visit!

    check "Backlogs"
    click_button "Save"

    expect_flash(type: :error, message:
      I18n.t(:"activerecord.errors.models.project.attributes.enabled_modules.dependency_missing",
             dependency: "Boards",
             module: "Backlogs"))

    expect(project.reload).not_to be_module_enabled("backlogs")

    check "Boards"
    click_button "Save"

    expect_flash type: :success, message: I18n.t(:notice_successful_update)

    expect(project.reload).to be_module_enabled("backlogs")
    expect(project).to be_module_enabled("board_view")
  end

  context "with both modules already enabled" do
    let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking backlogs board_view]) }

    it "refuses to disable Boards while Backlogs stays enabled" do
      modules_settings_page.visit!

      uncheck "Boards"
      click_button "Save"

      expect_flash(type: :error, message:
        I18n.t(:"activerecord.errors.models.project.attributes.enabled_modules.dependency_missing",
               dependency: "Boards",
               module: "Backlogs"))

      expect(project.reload).to be_module_enabled("board_view")
    end
  end
end
