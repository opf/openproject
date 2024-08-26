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

RSpec.describe "Wysiwyg attribute macros", :js do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }
  let(:editor) { Components::WysiwygEditor.new }
  let(:markdown) do
    <<~MD
      # My headline

      <table>
        <thead>
        <tr>
          <th>Label</th>
          <th>Value</th>
        </tr>
        </thead>
        <tbody>
        <tr>
          <td>workPackageLabel:"Foo Bar":subject</td>
          <td>workPackageValue:"Foo Bar":subject</td>
        </tr>
        <tr>
          <td>projectLabel:identifier</td>
          <td>projectValue:identifier</td>
        </tr>
        <tr>
          <td>invalid subject workPackageValue:"Invalid":subject</td>
          <td>invalid project projectValue:"does not exist":identifier</td>
        </tr>

        <tr>
          <td>work package start date workPackageValue:"Foo Bar":startDate</td>
          <td>work package due date workPackageValue:"Foo Bar":dueDate</td>
          <td>work package date workPackageValue:"Foo Bar":date</td>
        </tr>

        <tr>
          <td>milestone start date workPackageValue:"Milestone":startDate</td>
          <td>milestone due date workPackageValue:"Milestone":dueDate</td>
          <td>milestone date workPackageValue:"Milestone":date</td>
        </tr>
        </tbody>
      </table>
    MD
  end

  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:type_task) { create(:type_task) }

  shared_let(:project) do
    create(:project,
           identifier: "some-project",
           types: [type_milestone, type_task],
           enabled_module_names: %w[wiki work_package_tracking])
  end
  shared_let(:work_package) do
    create(:work_package,
           subject: "Foo Bar",
           project:,
           start_date: "2023-01-01",
           due_date: "2023-01-05",
           type: type_task)
  end
  shared_let(:milestone) do
    create(:work_package,
           subject: "Milestone",
           project:,
           due_date: "2023-01-10",
           type: type_milestone)
  end

  before do
    login_as(user)
  end

  describe "creating a wiki page" do
    before do
      visit project_wiki_path(project, :wiki)
    end

    it "can add and save multiple code blocks (Regression #28350)" do
      editor.in_editor do |container,|
        editor.set_markdown markdown
        expect(container).to have_table
      end

      click_on "Save"

      expect(page).to have_css(".op-toast.-success")

      # Expect output widget
      within("#content") do
        expect(page).to have_css("td", text: "Subject")
        expect(page).to have_css("td", text: "Foo Bar")
        expect(page).to have_css("td", text: "Identifier")
        expect(page).to have_css("td", text: "some-project")

        expect(page).to have_css("td", text: "invalid subject Cannot expand macro: Requested resource could not be found")
        expect(page).to have_css("td", text: "invalid project Cannot expand macro: Requested resource could not be found")

        expect(page).to have_css("td", text: "work package start date 01/01/2023")
        expect(page).to have_css("td", text: "work package due date 01/05/2023")
        expect(page).to have_css("td", text: "work package date 01/01/2023 - 01/05/2023")

        expect(page).to have_css("td", text: "milestone start date 01/10/2023")
        expect(page).to have_css("td", text: "milestone due date 01/10/2023")
        expect(page).to have_css("td", text: "milestone date 01/10/2023")
      end

      # Edit page again
      click_on "Edit"

      editor.in_editor do |container,|
        expect(container).to have_css("tbody td", count: 15)
      end
    end

    context "with a multi-select CF" do
      let!(:type) { create(:type, projects: [project]) }
      let!(:custom_field) do
        create(
          :list_wp_custom_field,
          name: "Ingredients",
          multi_value: true,
          types: [type],
          projects: [project],
          possible_values: %w[A B C D E F G H]
        )
      end

      let!(:work_package) do
        wp = build(:work_package, subject: "Foo Bar", project:, type:)

        wp.custom_field_values = {
          custom_field.id => %w[A B C D E F].map { |s| custom_field.custom_options.find { |co| co.value == s }.id }
        }

        wp.save!
        wp
      end

      it "expands all custom values (Regression #45538)" do
        editor.in_editor do |container,|
          editor.set_markdown 'workPackageValue:"Foo Bar":Ingredients'
          expect(container).to have_text "workPackageValue"
        end

        click_on "Save"

        expect(page).to have_css(".op-toast.-success")

        within("#content") do
          expect(page).to have_css(".custom-option", count: 6)
        end
      end
    end
  end

  describe "recursively referencing descriptions (Regression #55320)" do
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

    before do
      work_package.update_column(:description, "Hello from wp workPackageValue:##{milestone.id}:description")
      milestone.update_column(:description, "Hello from milestone workPackageValue:##{work_package.id}:description")
    end

    it "does not runaway" do
      wp_page.visit!

      expect(page).to have_text("Hello from wp")
      expect(page).to have_text("Hello from milestone")

      expect(page).to have_text("This macro is recursively referencing workPackage ##{milestone.id}")
    end
  end
end
