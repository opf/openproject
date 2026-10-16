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

RSpec.describe "New deploy target", :js do
  current_user { create(:admin) }

  it "saves the deploy target and redirects to the list" do
    visit new_deploy_target_path

    expect(page).to have_field("Type", disabled: true, with: "OpenProject")

    fill_in "Host", with: "https://qa.openproject-edge.com"
    fill_in "API key", with: "s3cr3t"
    click_button "Save"

    expect(page).to have_current_path(deploy_targets_path)
    expect(page).to have_text(I18n.t(:notice_deploy_target_created))
    expect(page).to have_text("https://qa.openproject-edge.com")

    deploy_target = DeployTarget.last
    expect(deploy_target.host).to eq("https://qa.openproject-edge.com")
    expect(deploy_target.api_key).to eq("s3cr3t")
    expect(deploy_target.type).to eq("OpenProject")
  end

  it "re-renders the form with an inline error when the host is blank" do
    visit new_deploy_target_path

    fill_in "API key", with: "s3cr3t"
    click_button "Save"

    expect(page).to have_current_path(new_deploy_target_path)
    expect(page).to have_text("can't be blank")
    expect(page).to have_field("API key", with: "s3cr3t")
  end
end
