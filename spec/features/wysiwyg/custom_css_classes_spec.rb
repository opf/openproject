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

RSpec.describe "Wysiwyg paragraphs in lists behavior (Regression #28765)", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project, enabled_module_names: %w[wiki]) }
  let(:editor) { Components::WysiwygEditor.new }

  let(:wiki_page) do
    page = build(:wiki_page)
    page.text = <<~MARKDOWN
      paragraph

      # h1

      ## h2

      ### h3

      #### h4

      ##### h5

      `code`

      ```text
      code snippet
      ```

      [link](http://link.com/)

      *   ul

      1.  ol

      *   [ ] task list

      <figure>
        <div>
          <img src="/attachments/44/content">
        </div>
        <figcaption>Image</figcaption>
      </figure>

      > Quote

      <figure>
        <table>
          <thead>
            <tr>
              <th>
                <br data-cke-filler="true">
              </th>
              <th>row header</th>
              <th>
                <br data-cke-filler="true">
              </th>
             </tr>
          </thead>
          <tbody>
            <tr>
              <th>column header</th>
              <td></td>
              <td></td>
            </tr>
          </tbody>
        </table>
      </figure>

      <macro class="toc"></macro>

      <macro class="embedded-table"></macro>

      <macro class="create_work_package_link" data-type="Milestone"></macro>

      <macro class="child_pages"></macro>
    MARKDOWN

    page
  end

  before do
    login_as(user)
    project.wiki.pages << wiki_page
    project.wiki.save!

    visit edit_project_wiki_path(project, wiki_page.slug)
  end

  it "custom classes are placed correctly" do
    editor.in_editor do |_container, editable|
      expect(editable).to have_css("p.op-uc-p", count: 6)
      expect(editable).to have_css("h1.op-uc-h1", count: 1)
      expect(editable).to have_css("h2.op-uc-h2", count: 1)
      expect(editable).to have_css("h3.op-uc-h3", count: 1)
      expect(editable).to have_css("h4.op-uc-h4", count: 1)
      expect(editable).to have_css("h5.op-uc-h5", count: 1)
      expect(editable).to have_css("blockquote.op-uc-blockquote", count: 1)
      expect(editable).to have_css("figure.op-uc-figure", count: 1)
      expect(editable).to have_css("figure.op-uc-figure.op-uc-figure_align-center table.op-uc-table", count: 1)
      expect(editable).to have_css("table.op-uc-table thead.op-uc-table--head", count: 1)
      expect(editable).to have_css("table.op-uc-table tr.op-uc-table--row", count: 2)
      expect(editable).to have_css("table.op-uc-table td.op-uc-table--cell", count: 2)
      expect(editable).to have_css("table.op-uc-table th.op-uc-table--cell.op-uc-table--cell_head", count: 4)
      expect(editable).to have_css("ul.op-uc-list", count: 2)
      expect(editable).to have_css("ol.op-uc-list", count: 1)
      expect(editable).to have_css("ul.op-uc-list_task-list", count: 1)
      expect(editable).to have_css("ul.op-uc-list li.op-uc-list--item", count: 2)
      expect(editable).to have_css("ol.op-uc-list li.op-uc-list--item", count: 1)
      expect(editable).to have_css("ul.op-uc-list.op-uc-list_task-list li.op-uc-list--item", count: 1)
      expect(editable).to have_css("pre.op-uc-code-block", count: 1)
      expect(editable).to have_css("code.op-uc-code", count: 1)
      expect(editable).to have_css("a.op-uc-link", count: 1)
      expect(editable).to have_css("div.op-uc-placeholder", count: 3)
      expect(editable).to have_css("span.op-uc-placeholder", count: 1)
    end
  end

  it "custom align classes are placed correctly" do
    editor.in_editor do |container, editable|
      # strangely, we need visible: :all here
      editor.click_toolbar_button "Insert table"
      # 2x2
      container.find(".ck-insert-table-dropdown-grid-box:nth-of-type(12)").click

      sleep(0.1)
      # There are already multiple tables on the page.
      # To avoid mixing them up, we need to select the appropriate one
      table = container.find(".op-uc-figure:first-of-type .op-uc-table")

      editor.align_table_by_label(editor, table, "Align table to the left")

      # Table figure should now has the proper alignment class
      expect(editable).to have_css("figure.op-uc-figure_align-start")

      editor.align_table_by_label(editor, table, "Align table to the right")

      # Table figure should now has the proper alignment class
      expect(editable).to have_css("figure.op-uc-figure_align-end")

      editor.align_table_by_label(editor, table, "Center table")

      # Table figure should now has the proper alignment class
      expect(editable).to have_css("figure.op-uc-figure_align-center")
    end
  end
end
