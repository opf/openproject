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

RSpec.describe "Projects#destroy", :js do
  let!(:project) { create(:project, name: "foo", identifier: "foo") }
  let(:project_page) { Pages::Projects::Settings::General.new(project) }

  current_user { create(:admin) }

  before do
    project_page.visit!
    project_page.click_delete_action
  end

  it "destroys the project" do
    expect(page).to have_modal "Delete project"
    within_modal "Delete project" do
      expect(page).to have_heading "Permanently delete this project?"

      expect(page).to have_unchecked_field "I understand that this deletion cannot be reversed."

      # Without confirmation, the button is disabled
      expect(page).to have_button "Delete permanently", disabled: true

      # Confirm the deletion
      check "I understand that this deletion cannot be reversed.", allow_label_click: true
      expect(page).to have_button "Delete permanently", disabled: false

      click_on "Delete permanently"
    end
    expect(page).to have_no_modal "Delete project"

    expect_flash type: :success, message: I18n.t("projects.delete.scheduled")
    expect(project.reload).to eq(project)

    perform_enqueued_jobs

    expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
