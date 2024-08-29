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

RSpec.describe "Wysiwyg work package linking", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %w[wiki work_package_tracking]) }
  let(:work_package) { create(:work_package, subject: "Foobar", project:) }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe "creating a wiki page" do
    before do
      visit project_wiki_path(project, :wiki)
    end

    it "can reference work packages" do
      # single hash autocomplete
      editor.click_and_type_slowly "##{work_package.id}"
      editor.click_autocomplete work_package.subject

      expect(editor.editor_element).to have_css("a.mention", text: "##{work_package.id}")

      # Save wiki page
      click_on "Save"

      expect(page).to have_css(".op-toast.-success")

      within("#content") do
        expect(page).to have_css("a.issue", count: 1)
      end
    end
  end
end
