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

RSpec.describe "Type schemes administration" do
  shared_let(:admin) { create(:admin) }
  shared_let(:type_a) { create(:type, name: "Alpha") }
  shared_let(:type_b) { create(:type, name: "Beta") }
  shared_let(:type_c) { create(:type, name: "Gamma") }

  def check_type(type, position: 1)
    check "type_scheme_types_#{type.id}_enabled"
    fill_in "type_scheme_types_#{type.id}_position", with: position
  end

  current_user { admin }

  it "creates a scheme with three types and a default and lists it" do
    visit new_admin_type_scheme_path
    fill_in "type_scheme_name", with: "Software"
    [type_a, type_b, type_c].each_with_index { |t, i| check_type(t, position: i + 1) }
    choose "type_scheme_default_type_#{type_b.id}"
    click_button "Create"

    expect(page).to have_text("Successful creation.")
    expect(page).to have_css("tr", text: "Software")
    scheme = TypeScheme.find_by!(name: "Software")
    expect(scheme.items.count).to eq 3
    expect(scheme.default_type).to eq type_b
  end

  context "with an existing scheme" do
    let!(:scheme) { create(:type_scheme, name: "Base", types: [type_a, type_b]) }

    it "clones it with a ' - Custom' suffix" do
      visit admin_type_schemes_path
      within("tr", text: "Base") { click_button "Clone" }

      expect(page).to have_css("tr", text: "Base - Custom")
    end

    it "deactivates it" do
      visit admin_type_schemes_path
      within("tr", text: "Base") { click_button "Deactivate" }

      expect(page).to have_css("tr", text: /Base.*Inactive/)
      expect(scheme.reload).not_to be_active
    end

    it "offers no way to delete a scheme" do
      visit admin_type_schemes_path
      expect(page).to have_no_button("Delete")
    end

    it "does not offer to deactivate the default scheme" do
      scheme.update!(is_default: true)
      visit admin_type_schemes_path
      within("tr", text: "Base") { expect(page).to have_no_button("Deactivate") }
    end

    it "reactivates an inactive scheme" do
      TypeSchemes::SchemeService.deactivate(scheme)
      visit admin_type_schemes_path
      within("tr", text: "Base") { click_button "Activate" }

      expect(scheme.reload).to be_active
    end

    context "when assigned to a project with work packages" do
      let!(:project) { create(:project, name: "Assigned project", types: [type_a, type_b]) }

      before do
        TypeSchemes::SchemeService.assign(project, scheme)
        create_list(:work_package, 2, project:, type: type_b)
      end

      it "asks for confirmation before removing a type and saves only on confirm" do
        visit edit_admin_type_scheme_path(scheme)
        uncheck "type_scheme_types_#{type_b.id}_enabled"
        click_button "Save"

        expect(page).to have_text("This scheme is used by 1 project. Changes will affect all projects.")
        expect(page).to have_text("Type Beta is currently used by 2 work packages.")
        expect(scheme.reload.items.count).to eq 2

        click_button "Confirm"

        expect(page).to have_text("Successful update.")
        expect(scheme.reload.items.map(&:type_id)).to eq [type_a.id]
      end
    end
  end

  context "as a non-admin" do
    current_user { create(:user) }

    it "is forbidden" do
      visit admin_type_schemes_path
      expect(page).to have_text("You are not authorized")
    end
  end
end
