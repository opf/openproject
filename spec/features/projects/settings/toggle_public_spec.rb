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

RSpec.describe "Project public/private toggle", :js do
  let(:permissions) { %i[edit_project] }
  let(:project) { create(:project, public: false) }
  let(:general_settings_page) { Pages::Projects::Settings::General.new(project) }

  current_user { create(:user, member_with_permissions: { project => permissions }) }

  it "allows toggling project visibility with confirmation" do
    expect(project).not_to be_public
    general_settings_page.visit!

    page.find_test_selector("project-settings-more-menu").click
    page.find_test_selector("project-settings--toggle-public").click

    expect(page).to have_text I18n.t("projects.settings.public_confirmation.title")

    retry_block do
      check I18n.t("projects.settings.public_confirmation.checkbox")
      click_button "Confirm"
    end

    expect(page).to have_test_selector("op-projects-public-warning")
    expect(page).to have_text(I18n.t("projects.settings.public_warning"))

    project.reload
    expect(project).to be_public

    # Toggle back to private
    page.find_test_selector("project-settings-more-menu").click
    page.find_test_selector("project-settings--toggle-public").click
    expect(page).to have_text I18n.t("projects.settings.private_confirmation.title")

    retry_block do
      check I18n.t("projects.settings.private_confirmation.checkbox")
      click_button "Confirm"
    end

    expect(page).not_to have_test_selector("op-projects-public-warning")
    expect(page).to have_no_text(I18n.t("projects.settings.public_warning"))

    # Verify project is now private
    project.reload
    expect(project).not_to be_public
  end
end
