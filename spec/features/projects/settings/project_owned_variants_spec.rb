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
require "support/pages/projects/settings/work_package_types"

RSpec.describe "Managing a project's own type variants", :js, with_flag: { type_variants: true } do
  shared_let(:stranger) { create(:project, name: "Someone else") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:global_variant) { create(:type, name: "Regression", parent: bug) }

  let(:project) { create(:project, name: "Apollo", types: [bug]) }
  let(:settings_page) { Pages::Projects::Settings::WorkPackageTypes.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[edit_project manage_types manage_project_variants view_work_packages]
           })
  end

  before do
    create(:type, name: "Their bug", parent: bug, project: stranger)
    settings_page.visit!
  end

  it "shows the family's global variants but never another project's" do
    settings_page.expand_family(bug)

    expect(page).to have_text("Regression")
    # The isolation criterion, seen where a project administrator would notice it.
    expect(page).to have_no_text("Their bug")
  end

  it "creates a variant the project owns and configures it without leaving the project" do
    settings_page.expand_family(bug)
    click_on "Add a variant for this project"

    expect(page).to have_field("Name")

    fill_in "Name", with: "Internal bug"
    click_on "Continue"

    # The variant is persisted after the first step, before the wizard moves on.
    expect(page).to have_no_field("Name", with: "Internal bug")

    created = project.owned_types.find_by(name: "Internal bug")
    expect(created).to be_present

    # The wizard must hand over to the project's own routes, not administration's.
    expect(page).to have_current_path(
      %r{/projects/#{project.identifier}/settings/work_packages/types/variants/#{created.id}/creation_wizard}
    )
  end

  context "for a member who may select types but not own variants" do
    current_user do
      create(:user, member_with_permissions: { project => %i[edit_project manage_types view_work_packages] })
    end

    it "offers no way to add one" do
      settings_page.expand_family(bug)

      expect(page).to have_no_link("Add a variant for this project")
    end
  end
end
