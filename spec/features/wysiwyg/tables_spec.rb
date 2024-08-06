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

RSpec.describe "Wysiwyg tables", :js do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }

  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as(user)
  end

  describe "in wikis" do
    describe "creating a wiki page" do
      before do
        visit project_wiki_path(project, :wiki)
      end

      it "can add tables without headers" do
        editor.in_editor do |container, editable|
          # strangely, we need visible: :all here
          container.find(".ck-button", visible: :all, text: "Insert table").click
          # 2x2
          container.find(".ck-insert-table-dropdown-grid-box:nth-of-type(12)").click

          # Edit table
          tds = editable.all(".op-uc-table .op-uc-table--cell")
          expect(tds.length).to eq(4)

          values = %w(h1 h&2 c1 c&2)
          tds.each_with_index do |td, i|
            td.click
            td.send_keys values[i]
            sleep 0.5
          end
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css("table td", text: "h1")
          expect(page).to have_css("table td", text: "h&2")
          expect(page).to have_css("table td", text: "c1")
          expect(page).to have_css("table td", text: "c&2")
        end
      end

      it "can add tables with headers" do
        editor.in_editor do |container, editable|
          editor.click_toolbar_button "Insert table"
          # 2x2
          container.find(".ck-insert-table-dropdown-grid-box:nth-of-type(12)").click

          # Edit table
          tds = editable.all(".op-uc-table .op-uc-table--cell")
          values = %w(h1 h2 a)
          expect(tds.length).to eq(4)

          tds.take(3).each_with_index do |td, i|
            td.click
            td.send_keys values[i]
            sleep 0.5
          end

          # Make first row th
          tds.first.click
          tds.first.send_keys :tab

          # Click row toolbar
          editor.click_hover_toolbar_button "Row"

          # Enable header row
          header_button = find(".ck-switchbutton", text: "Header row")
          header_button.find(".ck-button__toggle").click

          # Table should now have header
          expect(editable).to have_css("th", count: 2)
          expect(editable).to have_css("td", count: 2)
          expect(editable).to have_css("th", text: "h1")
          expect(editable).to have_css("th", text: "h2")
          expect(editable).to have_css("td", text: "a")
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css("table th", text: "h1")
          expect(page).to have_css("table th", text: "h2")
          expect(page).to have_css("table td", count: 2)
          expect(page).to have_css("td", text: "a")
        end

        SeleniumHubWaiter.wait
        # Edit again
        click_on "Edit"

        editor.in_editor do |_container, editable|
          # Table should still have header
          expect(editable).to have_css("th", count: 2)
          expect(editable).to have_css("td", count: 2)
          expect(editable).to have_css("th", text: "h1")
          expect(editable).to have_css("th", text: "h2")
          expect(editable).to have_css("td", text: "a")
        end
      end

      it "can add styled tables" do
        editor.in_editor do |container, editable|
          # strangely, we need visible: :all here
          editor.click_toolbar_button "Insert table"
          # 2x2
          container.find(".ck-insert-table-dropdown-grid-box:nth-of-type(12)").click

          # Edit table
          tds = editable.all(".op-uc-table .op-uc-table--cell")
          expect(tds.length).to eq(4)

          values = %w(h1 h2 a)
          tds.take(3).each_with_index do |td, i|
            td.click
            td.send_keys values[i]
            sleep 0.5
          end

          # style first td
          tds.first.click

          # Click row toolbar
          editor.click_hover_toolbar_button "Cell properties"

          # Enable header row
          expect(page).to have_css(".ck-input-color input", count: 2)
          # Pick the latter one, it's the background color
          page.all(".ck-input-color input").last.set "#123456"
          # Set vertical center / horizontal top
          editor.click_hover_toolbar_button "Align cell text to the center"
          editor.click_hover_toolbar_button "Align cell text to the top"
          find(".ck-button-save").click

          # Table should now have header
          expect(editable).to have_css('td[style*="background-color:#123456"]')
          expect(editable).to have_css('td[style*="text-align:center"]')
          expect(editable).to have_css('td[style*="vertical-align:top"]')
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css('td[style*="background-color:#123456"]')
          expect(page).to have_css('td[style*="text-align:center"]')
          expect(page).to have_css('td[style*="vertical-align:top"]')
        end

        SeleniumHubWaiter.wait
        # Edit again
        click_on "Edit"

        editor.in_editor do |_container, editable|
          expect(editable).to have_css('td[style*="background-color:#123456"]')

          # Change table styles
          tds = editable.all(".op-uc-table .op-uc-table--cell")

          # For some reason, the entire table is still selected so use tab to move to the next cell
          tds[0].click
          tds[0].send_keys :tab

          editor.click_hover_toolbar_button "Table properties"

          # Set style to dotted
          page.find(".ck-table-form__border-style").click
          page.find(".ck-button_with-text", text: "Dotted").click
          page.find(".ck-table-form__border-row .ck-input-color").set "black"
          page.find(".ck-table-form__border-width .ck-input-text").set "10px"

          # background
          page.find(".ck-table-properties-form__background .ck-input-text").set "red"

          # width, height
          page.find(".ck-table-form__dimensions-row__width .ck-input-text").set "500px"
          page.find(".ck-table-form__dimensions-row__height .ck-input-text").set "500px"
          find(".ck-button-save").click

          # table height and width is set on figure
          expect(editable).to have_css('figure[style*="width:500px"]')
          expect(editable).to have_css('figure[style*="height:500px"]')

          # rest is set on table
          expect(editable).to have_css('table[style*="background-color:red"]')
          expect(editable).to have_css('table[style*="border-style:dotted"]')
          expect(editable).to have_css('table[style*="border-width:10px"]')
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          # table height and width is set on figure
          expect(page).to have_css('figure[style*="width:500px"]')
          expect(page).to have_css('figure[style*="height:500px"]')

          # rest is set on table
          expect(page).to have_css('table[style*="background-color:red"]')
          expect(page).to have_css('table[style*="border-style:dotted"]')
          expect(page).to have_css('table[style*="border-width:10px"]')
        end

        # Edit again
        click_on "Edit"

        # Expect all previous changes to be there
        editor.in_editor do |_container, editable|
          expect(editable).to have_css('td[style*="background-color:#123456"]')

          # table height and width is set on figure
          expect(editable).to have_css('figure[style*="width:500px"]')
          expect(editable).to have_css('figure[style*="height:500px"]')

          # rest is set on table
          expect(editable).to have_css('table[style*="background-color:red"]')
          expect(editable).to have_css('table[style*="border-style:dotted"]')
          expect(editable).to have_css('table[style*="border-width:10px"]')
        end
      end

      it "can restrict table cell width" do
        editor.in_editor do |container, editable|
          # strangely, we need visible: :all here
          editor.click_toolbar_button "Insert table"
          # 2x2
          container.find(".ck-insert-table-dropdown-grid-box:nth-of-type(12)").click

          # Edit table
          tds = editable.all(".op-uc-table .op-uc-table--cell")
          expect(tds.length).to eq(4)

          values = %w(h1 h2 a)
          tds.take(3).each_with_index do |td, i|
            td.click
            td.send_keys values[i]
            sleep 0.5
          end

          # style first td
          tds.first.click

          # Click row toolbar
          editor.click_hover_toolbar_button "Cell properties"

          # Enable header row
          find(".ck-table-form__dimensions-row__width input").set "250px"
          find(".ck-button-save").click

          expect(editable).to have_css('td[style*="width:250px"]')
        end

        # Save wiki page
        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css('td[style*="width:250px"]')
        end

        SeleniumHubWaiter.wait
        # Edit again
        click_on "Edit"

        editor.in_editor do |_container, editable|
          expect(editable).to have_css('td[style*="width:250px"]')
        end
      end
    end

    describe "editing a wiki page with tables" do
      let(:wiki_page) do
        page = build(:wiki_page,
                     title: "Wiki page with titles")
        page.text = <<~MARKDOWN

          ## This is markdown!

          <table>
            <thead>
              <tr>
                <th>A</th>
                <th>B</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td> c1 </td>
                <td> c2 </td>
              </tr>
              <tr>
                <td> c3 </td>
                <td> c4 </td>
              </tr>
            </tbody>
          </table>
        MARKDOWN

        page
      end

      before do
        project.wiki.pages << wiki_page
        project.wiki.save!

        visit project_wiki_path(project, wiki_page.slug)
      end

      it "can show the table with header" do
        within("#content") do
          expect(page).to have_css("h2", text: "This is markdown")

          expect(page).to have_css("table thead th", text: "A")
          expect(page).to have_css("table thead th", text: "B")
          expect(page).to have_css("table td", text: "c1")
          expect(page).to have_css("table td", text: "c2")
          expect(page).to have_css("table td", text: "c3")
          expect(page).to have_css("table td", text: "c4")
        end

        # Edit the table
        click_on "Edit"

        # Expect wysiwyg to render table
        editor.in_editor do |_, editable|
          expect(editable).to have_css("h2", text: "This is markdown")

          expect(editable).to have_css("table thead th", text: "A")
          expect(editable).to have_css("table thead th", text: "B")
          expect(editable).to have_css("table td", text: "c1")
          expect(editable).to have_css("table td", text: "c2")
          expect(editable).to have_css("table td", text: "c3")
          expect(editable).to have_css("table td", text: "c4")
        end
      end
    end
  end
end
