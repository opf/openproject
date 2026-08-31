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

RSpec.describe "Workflow copy from role", :js do
  let!(:type) { create(:type) }
  let!(:roles) { create_list(:project_role, 3) }
  let(:admin)  { create(:admin) }

  let(:target_roles_autocompleter) { FormFields::Primerized::AutocompleteField.new("target_roles", selector: "[data-test-selector='target_roles_autocomplete']") }

  current_user { admin }

  shared_examples "a copy-to-other-roles dialog" do |with_source_role:, host:|
    it "permits to select a source role and target roles" do
      # TODO: Remove with type_variants feature flag
      unless with_source_role
        choose "Copy to other roles"

        expect(page).to have_select("Source role", text: roles.first.name)
        select(roles.last.name, from: "Source role")
      end

      target_roles_autocompleter.select_option roles.first.name, roles.second.name
      target_roles_autocompleter.close_autocompleter

      click_button "Copy"

      expect(page).to have_css(".flash-success", text: "Successfully copied workflow to 2 roles.")
      # Copying to other roles stays within the same type, so the current path is kept
      current_path = if host == :wizard
                       type_creation_wizard_path(type_id: type,
                                                 step: :workflows)
                     else
                       edit_type_workflow_path(type_id: type)
                     end
      expect(page).to have_current_path(current_path)
      expect(page).to have_text("2 roles selected")
    end
  end

  describe "from the workflow tab" do
    before do
      visit edit_type_workflow_path(type_id: type)
      click_link "Copy"
    end

    it_behaves_like "a copy-to-other-roles dialog", with_source_role: true, host: :tab
  end

  describe "from the creation wizard", with_flag: { type_variants: true } do
    before do
      visit type_creation_wizard_path(type_id: type, step: :workflows)
      # Scope to the matrix; the wizard's reuse banner also has a "Copy from type" button.
      within("#workflow-table") { click_link "Copy" }
    end

    it_behaves_like "a copy-to-other-roles dialog", with_source_role: true, host: :wizard
  end
end
