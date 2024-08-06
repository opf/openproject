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

RSpec.describe "Wysiwyg bold behavior", :js, :with_cuprite do
  current_user { create(:admin) }

  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { Components::WysiwygEditor.new }

  def mac_osx?
    RUBY_PLATFORM.include?("darwin")
  end

  def bold_keystroke
    if mac_osx?
      [:meta, "b"]
    else
      [:ctrl, "b"]
    end
  end

  describe "in wikis" do
    describe "creating a wiki page" do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it "can insert strong formatting with nbsp" do
        editor.click_and_type_slowly "some text ", bold_keystroke, "with bold"

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css("p") { |node|
            node.text.include?("some text") && node.text.include?("with bold")
          }
          expect(page).to have_css("strong", text: "with bold")
        end
      end
    end
  end
end
