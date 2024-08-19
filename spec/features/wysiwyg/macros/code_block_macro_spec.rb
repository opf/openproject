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

RSpec.describe "Wysiwyg code block macro", :js do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { Components::WysiwygEditor.new }

  let(:snippet) do
    <<~RUBY
      def foobar
        'some ruby code'
      end
    RUBY
  end

  let(:expected) do
    <<~EXPECTED
      ```ruby
      #{snippet.strip}
      ```
    EXPECTED
  end

  before do
    login_as(user)
  end

  describe "in wikis" do
    describe "creating a wiki page" do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it "can add and save multiple code blocks (Regression #28350)" do
        editor.in_editor do |container,|
          editor.set_markdown expected

          # Expect first macro saved to editor
          expect(container).to have_css(".op-uc-code-block", text: snippet)
          expect(container).to have_css(".op-uc-code-block--language", text: "ruby")

          editor.set_markdown "#{expected}\n#{expected}"
          expect(container).to have_css(".op-uc-code-block", text: snippet, count: 2)
          expect(container).to have_css(".op-uc-code-block--language", text: "ruby", count: 2)
        end

        click_on "Save"
        expect(page).to have_css(".op-toast.-success")

        # Expect output widget
        within("#content") do
          expect(page).to have_css("pre.highlight-ruby", count: 2)
        end

        SeleniumHubWaiter.wait
        # Edit page again, expect widget
        click_on "Edit"
        # SeleniumHubWaiter.wait

        editor.in_editor do |container,|
          expect(container).to have_css(".op-uc-code-block", text: snippet, count: 2)
          expect(container).to have_css(".op-uc-code-block--language", text: "ruby", count: 2)
        end
      end

      it "respects the inserted whitespace" do
        editor.in_editor do |container,|
          editor.click_toolbar_button "Insert code snippet"

          expect(page).to have_css(".spot-modal")

          # CM wraps an accessor to the editor instance on the outer container
          cm = page.find(".CodeMirror")
          page.execute_script("arguments[0].CodeMirror.setValue(arguments[1]);", cm.native, "asdf")
          find(".spot-modal--submit-button").click

          expect(container).to have_css(".op-uc-code-block", text: "asdf")

          click_on "Save"
          expect(page).to have_css(".op-toast.-success")

          wp = WikiPage.last
          expect(wp.text.gsub("\r\n", "\n")).to eq("```text\nasdf\n```")

          SeleniumHubWaiter.wait
          click_on "Edit"

          editor.in_editor do |container,|
            expect(container).to have_css(".op-uc-code-block", text: "asdf")
          end

          click_on "Save"
          expect(page).to have_css(".op-toast.-success")

          wp.reload
          # Regression added two newlines before fence here
          expect(wp.text.gsub("\r\n", "\n")).to eq("```text\nasdf\n```")
        end
      end

      it "can add and edit a code block widget" do
        editor.in_editor do |container,|
          editor.click_toolbar_button "Insert code snippet"

          expect(page).to have_css(".spot-modal")

          # CM wraps an accessor to the editor instance on the outer container
          cm = page.find(".CodeMirror")
          page.execute_script("arguments[0].CodeMirror.setValue(arguments[1]);", cm.native, snippet)

          fill_in "selected-language", with: "ruby"

          # Expect some highlighting classes
          expect(page).to have_css(".cm-keyword", text: "def")
          expect(page).to have_css(".cm-def", text: "foobar")

          find(".spot-modal--submit-button").click

          # Expect macro saved to editor
          expect(container).to have_css(".op-uc-code-block", text: snippet)
          expect(container).to have_css(".op-uc-code-block--language", text: "ruby")
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        wiki_page = project.wiki.find_page("wiki")
        text = wiki_page.text.gsub(/\r\n?/, "\n")
        expect(text.strip).to eq(expected.strip)

        # Expect output widget
        within("#content") do
          expect(page).to have_css("pre.highlight-ruby")
        end

        # Edit page again, expect widget
        SeleniumHubWaiter.wait
        click_on "Edit"

        editor.in_editor do |container,|
          expect(container).to have_css(".op-uc-code-block", text: snippet)
          expect(container).to have_css(".op-uc-code-block--language", text: "ruby")

          widget = container.find(".op-uc-code-block")
          page.driver.browser.action.double_click(widget.native).perform
          expect(page).to have_css(".spot-modal")

          expect(page).to have_css(".op-uc-code-block--language", text: "ruby")
          expect(page).to have_css(".cm-keyword", text: "def")
          expect(page).to have_css(".cm-def", text: "foobar")
        end
      end
    end
  end
end
