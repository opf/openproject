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

RSpec.describe "Permission explanations in the role form", :js do
  let!(:admin) { create(:admin) }
  let(:documentation_url) do
    OpenProject::Static::Links.url_for(:sysadmin_docs, :project_identifier_visibility)
  end
  let(:caution_text) do
    "check whether a project identifier is already in use across the entire instance"
  end

  before do
    login_as admin
    visit new_role_path
  end

  it "cautions about identifier enumeration below the 'Create subprojects' permission" do
    expect(page).to have_field("Create subprojects")

    expect(page).to have_text(caution_text)
    expect(page).to have_link("Learn more", href: documentation_url)
  end

  it "cautions about identifier enumeration below the global 'Create projects' permission" do
    check "Global role"

    expect(page).to have_field("Create projects")

    expect(page).to have_text(caution_text)
    expect(page).to have_link("Learn more", href: documentation_url)
  end

  it "still renders plain explanations of other permissions" do
    expect(page)
      .to have_text(I18n.t(:permission_copy_projects_explanation))
  end
end
