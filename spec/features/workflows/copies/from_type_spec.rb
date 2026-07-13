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

RSpec.describe "Workflow copy from type", :js do
  let!(:types) { create_list(:type, 3) }
  let!(:type) { types.first }
  let(:admin) { create(:admin) }
  let(:target_types_autocompleter) { FormFields::Primerized::AutocompleteField.new("target_types", selector: "[data-test-selector='target_types_autocomplete']") }

  current_user { admin }

  shared_examples "a copy-to-another-type dialog" do |with_source_role:|
    it "permits to select target types" do
      if with_source_role
        choose "Copy to another type"
      end

      target_types_autocompleter.select_option types.second.name, types.last.name
      target_types_autocompleter.close_autocompleter

      click_button "Copy"

      expect(page).to have_css(".flash-success", text: "Successfully copied workflow to 2 types.")
      expect(page).to have_current_path(edit_workflow_path(types.second))
    end
  end

  describe "from the workflows index page" do
    before do
      visit workflows_path
      within "li", text: type.name do
        find("button[aria-haspopup=true]").click
        click_link "Copy"
      end
    end

    it_behaves_like "a copy-to-another-type dialog", with_source_role: false
  end

  describe "from the workflows edit page" do
    before do
      visit edit_workflow_path(type)
      click_link "Copy"
    end

    it_behaves_like "a copy-to-another-type dialog", with_source_role: true
  end
end
