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

require_relative "../support/pages/meetings/index"

RSpec.describe "Meetings new", :js, with_cuprite: false do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:admin) { create(:admin) }
  let(:time_zone) { "utc" }
  let(:user) do
    create(:user,
           lastname: "First",
           member_with_permissions: { project => permissions }).tap do |u|
      u.pref[:time_zone] = time_zone

      u.save!
    end
  end
  let(:other_user) do
    create(:user,
           lastname: "Second",
           member_with_permissions: { project => permissions })
  end
  let(:permissions) { %i[view_meetings create_meetings] }
  let(:current_user) { user }

  before do
    login_as current_user
  end

  context "when creating a meeting from the global page" do
    before do
      other_user
      project
    end

    let(:index_page) { Pages::Meetings::Index.new(project: nil) }
    let(:new_page) { Pages::Meetings::New.new(nil) }

    context "with permission to create meetings" do
      it "does not render menus", :with_cuprite do
        new_page.visit!
        new_page.expect_no_main_menu
      end

      describe "clicking on the create new meeting button", :with_cuprite do
        it "navigates to the global create form" do
          index_page.visit!
          index_page.click_create_new
          expect(page).to have_current_path(new_page.path)
        end
      end

      ["CET", "UTC", "", "Pacific Time (US & Canada)"].each do |zone|
        let(:time_zone) { zone }

        it "allows creating a project and handles errors in time zone #{zone}" do
          new_page.visit!

          expect_angular_frontend_initialized # Wait for project dropdown to be ready

          new_page.set_title "Some title"
          new_page.set_type "Classic"
          new_page.set_project project

          new_page.set_start_date "2013-03-28"
          new_page.set_start_time "13:30"
          new_page.set_duration "1.5"
          new_page.invite(other_user)

          show_page = new_page.click_create

          show_page.expect_toast(message: "Successful creation")

          show_page.expect_invited(user, other_user)

          show_page.expect_date_time "03/28/2013 01:30 PM - 03:00 PM"
        end
      end

      context "without a title set" do
        before do
          new_page.visit!

          # Wait for project dropdown to be initialized
          expect_angular_frontend_initialized

          new_page.set_project project

          new_page.set_start_date "2013-03-28"
          new_page.set_start_time "13:30"
          new_page.set_duration "1.5"
          new_page.invite(other_user)
        end

        it "renders a validation error" do
          expect do
            new_page.click_create
          end.not_to change(Query, :count)

          # HTML required attribute validation error
          expect(page).to have_current_path(new_page.path)
        end
      end

      context "without a project set" do
        before do
          new_page.visit!
          new_page.set_title "Some title"
          new_page.set_type "Classic"
          new_page.set_start_date "2013-03-28"
          new_page.set_start_time "13:30"
          new_page.set_duration "1.5"
        end

        it "renders a validation error" do
          new_page.click_create

          new_page.expect_toast(message: "#{Project.model_name.human} #{I18n.t('activerecord.errors.messages.blank')}",
                                type: :error)

          new_page.expect_project_dropdown
        end
      end
    end

    context "without permission to create meetings", :with_cuprite do
      let(:permissions) { %i[view_meetings] }

      it "shows no edit link" do
        index_page.visit!

        index_page.expect_no_create_new_button
      end
    end

    context "as an admin", :with_cuprite do
      let(:current_user) { admin }

      it "allows creating meeting in a project without members" do
        new_page.visit!

        expect_angular_frontend_initialized # Wait for project dropdown to be ready

        new_page.set_title "Some title"
        new_page.set_type "Classic"

        new_page.set_project project

        wait_for_network_idle # Wait for participant section to be fetched

        show_page = new_page.click_create

        show_page.expect_toast(message: "Successful creation")

        # Not sure if that is then intended behaviour but that is what is currently programmed
        show_page.expect_invited(admin)
      end

      context "without a project set" do
        before do
          new_page.visit!
          new_page.set_title "Some title"
          new_page.set_type "Classic"
        end

        it "renders a validation error" do
          new_page.click_create

          new_page.expect_toast(message: "#{Project.model_name.human} #{I18n.t('activerecord.errors.messages.blank')}",
                                type: :error)
          new_page.expect_project_dropdown
        end
      end

      context "without a title set" do
        before do
          new_page.visit!

          # Wait for project dropdown to be initialized
          expect_angular_frontend_initialized

          new_page.set_project project
        end

        it "renders a validation error" do
          expect do
            new_page.click_create
          end.not_to change(Query, :count)

          # HTML required attribute validation error
          expect(page).to have_current_path(new_page.path)
        end
      end
    end
  end

  context "when creating a meeting from the project-specific page" do
    let(:index_page) { Pages::Meetings::Index.new(project:) }
    let(:new_page) { Pages::Meetings::New.new(project) }

    context "with permission to create meetings" do
      before do
        other_user
      end

      describe "clicking on the create new meeting button", :with_cuprite do
        it "navigates to the project-specific create form" do
          index_page.visit!
          index_page.click_create_new
          expect(page).to have_current_path(new_page.path)
        end
      end

      ["CET", "UTC", "", "Pacific Time (US & Canada)"].each do |zone|
        let(:time_zone) { zone }

        it "allows creating a project and handles errors in time zone #{zone}" do
          new_page.visit!

          new_page.set_title "Some title"
          new_page.set_type "Classic"
          new_page.set_start_date "2013-03-28"
          new_page.set_start_time "13:30"
          new_page.set_duration "1.5"
          new_page.invite(other_user)

          show_page = new_page.click_create

          show_page.expect_toast(message: "Successful creation")

          show_page.expect_invited(user, other_user)

          show_page.expect_date_time "03/28/2013 01:30 PM - 03:00 PM"
        end
      end

      context "without a title set" do
        before do
          new_page.visit!
          new_page.set_start_date "2013-03-28"
          new_page.set_start_time "13:30"
          new_page.set_duration "1.5"
          new_page.invite(other_user)
        end

        it "renders a validation error" do
          expect do
            new_page.click_create
          end.not_to change(Query, :count)

          # HTML required attribute validation error
          expect(page).to have_current_path(new_page.path)
        end
      end
    end

    context "without permission to create meetings", :with_cuprite do
      let(:permissions) { %i[view_meetings] }

      it "shows no edit link" do
        index_page.visit!

        index_page.expect_no_create_new_button
      end
    end

    context "as an admin", :with_cuprite do
      let(:current_user) { admin }
      let(:field) do
        TextEditorField.new(page,
                            "",
                            selector: test_selector("op-meeting--meeting_agenda"))
      end

      it "allows creating meeting in a project without members" do
        new_page.visit!

        new_page.set_type "Classic"
        new_page.set_title "Some title"

        # Ensure we have the correct type labels set up (Regression #15625)
        dynamic_button = find_field "Dynamic"
        classic_button = find_field "Classic"

        expect(page).to have_css("label[for='#{dynamic_button[:id]}']")
        expect(page).to have_css("label[for='#{classic_button[:id]}']")

        show_page = new_page.click_create

        show_page.expect_toast(message: "Successful creation")

        # Not sure if that is then intended behaviour but that is what is currently programmed
        show_page.expect_invited(admin)
      end

      context "without a title set" do
        before do
          new_page.visit!
        end

        it "renders a validation error" do
          expect do
            new_page.click_create
          end.not_to change(Query, :count)

          # HTML required attribute validation error
          expect(page).to have_current_path(new_page.path)
        end
      end

      it "can save the meeting agenda via cmd+Enter" do
        new_page.visit!

        new_page.set_title "Some title"
        new_page.set_type "Classic"

        show_page = new_page.click_create

        show_page.expect_toast(message: "Successful creation")

        meeting = Meeting.last

        field.set_value("My new meeting text")

        field.submit_by_enter

        show_page.expect_and_dismiss_toaster message: "Successful update"

        meeting.reload

        expect(meeting.agenda.text).to eq "My new meeting text"
      end
    end
  end
end
