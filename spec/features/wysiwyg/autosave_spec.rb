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

RSpec.describe "Wysiwyg autosave spec",
               :js,
               :with_cuprite do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %w[wiki work_package_tracking]) }
  shared_let(:work_package) { create(:work_package, subject: "Foobar", project:) }

  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe "creating a wiki page" do
    before do
      visit project_wiki_path(project, :wiki)
    end

    it "can autosave" do
      editor.click_and_type_slowly "Initial version"
      click_on "Save"

      expect(page).to have_css(".op-toast.-success")
      within("#content") do
        expect(page).to have_text "Initial version"
      end

      # Edit again
      click_on "Edit"

      editor.set_markdown "This should be saved"
      editor.trigger_autosave

      retry_block do
        editor.click_hover_toolbar_button "Show local modifications"
        page.find(".ck-button", text: /current - .+? seconds ago \(4 words\)/)
      end

      # Save wiki page
      click_on "Save"

      expect(page).to have_css(".op-toast.-success")
      within("#content") do
        expect(page).to have_text "This should be saved"
      end

      wiki_page = WikiPage.last

      keys = page.evaluate_script "Object.keys(localStorage)"
      expect(keys).to include "op_ckeditor_rev_/api/v3/wiki_pages/#{wiki_page.id}_page[text]"

      # Edit again
      click_on "Edit"

      editor.set_markdown "Another change"
      editor.trigger_autosave

      retry_block do
        editor.click_hover_toolbar_button "Show local modifications"
        page.find(".ck-button", text: /current - .+? seconds ago \(2 words\)/)

        page
          .find(".ck-button", text: /.+? (seconds|minutes) ago \(4 words\)/)
          .click
      end

      expect(editor.editor_element).to have_text "This should be saved"
    end
  end
end
