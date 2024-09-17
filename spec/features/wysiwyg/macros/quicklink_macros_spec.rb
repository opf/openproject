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

RSpec.describe "Wysiwyg work package quicklink macros", :js do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project_with_types) }
  let(:work_package) do
    create(:work_package,
           subject: "My subject",
           start_date: Date.parse("2020-01-01"),
           due_date: Date.parse("2020-02-01"))
  end
  let(:editor) { Components::WysiwygEditor.new }

  before do
    set_factory_default(:user, user)
    set_factory_default(:project_with_types, project)
    login_as(user)
    visit project_wiki_path(project, :wiki)
  end

  it "renders work package quicklink macro # with id linking to work package" do
    editor.set_markdown "##{work_package.id}"
    click_on "Save"

    # Expect output widget
    within("#content") do
      expect(page).to have_link("##{work_package.id}")
      expect(page).to have_no_css(".work-package--quickinfo.preview-trigger")
    end

    # Edit page again
    click_on "Edit"

    editor.in_editor do |container,|
      expect(container).to have_css("p", text: "##{work_package.id}")
    end
  end

  it "renders work package quicklink macro ## with id link, subject and type" do
    editor.set_markdown "###{work_package.id}"
    click_on "Save"

    # Expect output widget
    within("#content") do
      expected_macro_text = "#{work_package.type.name.upcase} ##{work_package.id}: My subject"
      expect(page).to have_css("opce-macro-wp-quickinfo", text: expected_macro_text)
      expect(page).to have_css("span", text: work_package.type.name.upcase)
      expect(page).to have_css(".work-package--quickinfo.preview-trigger", text: "##{work_package.id}")
      expect(page).to have_css("span", text: "My subject")
    end

    # Edit page again
    click_on "Edit"

    editor.in_editor do |container,|
      expect(container).to have_css("p", text: "###{work_package.id}")
    end
  end

  it "renders work package quicklink macro ### with id link, subject, type, status, and dates" do
    editor.set_markdown "####{work_package.id}"
    click_on "Save"

    # Expect output widget
    within("#content") do
      expected_macro_text = "#{work_package.status.name}#{work_package.type.name.upcase} " \
                            "##{work_package.id}: My subject (01/01/2020 - 02/01/2020)"
      expect(page).to have_css("opce-macro-wp-quickinfo", text: expected_macro_text)
      expect(page).to have_css("span", text: work_package.status.name)
      expect(page).to have_css("span", text: work_package.type.name.upcase)
      expect(page).to have_css(".work-package--quickinfo.preview-trigger", text: "##{work_package.id}")
      expect(page).to have_css("span", text: "My subject")
      # Dates are being rendered in two nested spans
      expect(page).to have_css("span", text: "01/01/2020", count: 2)
      expect(page).to have_css("span", text: "02/01/2020", count: 2)
    end

    # Edit page again
    click_on "Edit"

    editor.in_editor do |container,|
      expect(container).to have_css("p", text: "####{work_package.id}")
    end
  end

  it "displays dates with work package detailed link macro only if a date is present" do
    wp_no_dates =
      create(:work_package,
             subject: "No dates",
             start_date: nil,
             due_date: nil)
    wp_start_date_only =
      create(:work_package,
             subject: "Start date only",
             start_date: Date.parse("2020-01-01"),
             due_date: nil)
    wp_end_date_only =
      create(:work_package,
             subject: "End date only",
             start_date: nil,
             due_date: Date.parse("2020-12-31"))
    wp_both_dates =
      create(:work_package,
             subject: "Both dates",
             start_date: Date.parse("2020-01-01"),
             due_date: Date.parse("2020-12-31"))
    wp_milestone_with_date =
      create(:work_package,
             :is_milestone,
             subject: "Milestone with date",
             start_date: Date.parse("2020-01-01"),
             due_date: Date.parse("2020-01-01"))
    wp_milestone_without_date =
      create(:work_package,
             :is_milestone,
             subject: "Milestone without date",
             start_date: nil,
             due_date: nil)

    editor.set_markdown <<~MD
      ####{wp_no_dates.id}

      ####{wp_start_date_only.id}

      ####{wp_end_date_only.id}

      ####{wp_both_dates.id}

      ####{wp_milestone_with_date.id}

      ####{wp_milestone_without_date.id}
    MD

    click_on "Save"

    within("#content") do
      expect(page).to have_css("opce-macro-wp-quickinfo", text: /No dates$/)
      expect(page).to have_css("opce-macro-wp-quickinfo", text: "Start date only (01/01/2020 - no finish date)")
      expect(page).to have_css("opce-macro-wp-quickinfo", text: "End date only (no start date - 12/31/2020)")
      expect(page).to have_css("opce-macro-wp-quickinfo", text: "Both dates (01/01/2020 - 12/31/2020)")
      expect(page).to have_css("opce-macro-wp-quickinfo", text: "Milestone with date (01/01/2020)")
      expect(page).to have_css("opce-macro-wp-quickinfo", text: /Milestone without date$/)
    end
  end
end
