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

require_relative "../support/pages/meetings/show"

RSpec.describe "Work package meeting outcomes", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:project) { create(:project_with_types, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create :user,
           lastname: "First",
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas manage_outcomes
                                                    view_work_packages add_work_packages] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end
  shared_let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
  shared_let(:work_package1) do
    create(:work_package,
           project:,
           subject: "Important task")
  end
  shared_let(:work_package2) do
    create(:work_package,
           project:,
           subject: "Another task")
  end

  let(:current_user) { user }
  let(:state) { :in_progress }
  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before do
    meeting.update!(state:)
    login_as current_user
  end

  context "when a user has the necessary permissions" do
    context "when the meeting is 'in progress'" do
      context "when linking an existing work package as an outcome" do
        it "can link an existing work package as an outcome" do
          show_page.visit!
          wait_for_network_idle

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            expect(page).to have_text("Existing work package")
            click_on "Existing work package"
          end

          expect(page).to have_test_selector("op-agenda-item-outcome-wp-autocomplete")
          select_autocomplete(find_test_selector("op-agenda-item-outcome-wp-autocomplete"),
                              query: "Important",
                              results_selector: "body")

          within(".meeting-agenda-item-outcome-form") do
            click_on "Add"
          end

          wait_for_network_idle

          show_page.in_outcome_component(meeting_agenda_item) do
            expect(page).to have_link(work_package1.subject)
          end
        end

        it "can cancel adding an existing work package outcome" do
          show_page.visit!
          wait_for_network_idle

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            click_on "Existing work package"
          end

          expect(page).to have_test_selector("op-agenda-item-outcome-wp-autocomplete")
          page.find_test_selector("op-agenda-item-outcome-wp-autocomplete").find(".ng-input input").send_keys(:escape)

          click_on "Cancel"

          expect(page).to have_no_test_selector("op-agenda-item-outcome-wp-autocomplete")
        end

        it "can delete a work package outcome" do
          outcome = create(:meeting_outcome,
                           meeting_agenda_item:,
                           work_package: work_package1,
                           kind: :work_package)

          show_page.visit!
          wait_for_network_idle

          show_page.in_outcome_component(meeting_agenda_item) do
            expect(page).to have_link(work_package1.subject)
            show_page.select_outcome_action "Remove outcome"
          end

          wait_for_network_idle

          expect(page).to have_no_link(work_package1.subject)
          expect { outcome.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when creating a new work package as an outcome" do
        it "can create a new work package and link it as an outcome" do
          show_page.visit!
          wait_for_network_idle

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            expect(page).to have_text("New work package")
            click_on "New work package"
          end

          expect(page).to have_dialog(I18n.t(:label_work_package_new))

          page.within_dialog(I18n.t(:label_work_package_new)) do
            fill_in "Subject", with: "New WP from meeting outcome"
            click_on "Create"
          end

          wait_for_network_idle

          expect(page).to have_no_selector(:dialog, I18n.t(:label_work_package_new), wait: 10)

          created_wp = WorkPackage.find_by(subject: "New WP from meeting outcome")
          expect(created_wp).to be_present
          expect(created_wp.project).to eq(project)

          show_page.in_outcome_component(meeting_agenda_item) do
            expect(page).to have_link(created_wp.subject)
          end
        end

        it "shows an inline validation error when subject is empty" do
          show_page.visit!
          wait_for_network_idle

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            expect(page).to have_text("New work package")
            click_on "New work package"
          end

          expect(page).to have_dialog(I18n.t(:label_work_package_new))

          page.within_dialog(I18n.t(:label_work_package_new)) do
            fill_in "Subject", with: ""

            click_on "Create"
          end

          wait_for_network_idle

          expect(page).to have_text("Subject can't be blank")

          expect(page).to have_dialog(I18n.t(:label_work_package_new))
          expect(WorkPackage.find_by(subject: "")).to be_nil
        end

        it "can cancel creating a new work package" do
          show_page.visit!
          wait_for_network_idle

          initial_wp_count = WorkPackage.count

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            expect(page).to have_text("New work package")
            click_on "New work package"
          end

          expect(page).to have_dialog(I18n.t(:label_work_package_new))

          page.within_dialog(I18n.t(:label_work_package_new)) do
            fill_in "Subject", with: "This should not be created"
            click_on "Cancel"
          end

          expect(page).to have_no_selector(:dialog, I18n.t(:label_work_package_new), wait: 10)
          expect(WorkPackage.count).to eq(initial_wp_count)
        end

        context "when changing the WP type" do
          let!(:type_without_template) { create(:type, name: "No template type") }
          let!(:type_with_template) do
            create(:type, name: "Templated type",
                          description: "Some default template text here...")
          end

          before do
            project.types = [type_without_template, type_with_template]
          end

          it "refreshes the form when the type is changed" do
            show_page.visit!
            wait_for_network_idle

            show_page.open_menu(meeting_agenda_item) do
              click_on "Add outcome"
              click_on "New work package"
            end

            expect(page).to have_dialog(I18n.t(:label_work_package_new))
            expect(page).to have_no_css(".ck-content", text: "Some default template text here...")

            page.within_dialog(I18n.t(:label_work_package_new)) do
              wait_for_turbo_stream do
                select_autocomplete(find_test_selector("work_package_create_dialog_type"),
                                    query: type_with_template.name,
                                    select_text: type_with_template.name.upcase,
                                    results_selector: "body")
              end
            end

            page.within_dialog(I18n.t(:label_work_package_new)) do
              expect(page).to have_css(".ck-content", text: "Some default template text here...")
            end
          end
        end
      end

      context "when user lacks add_work_packages permission" do
        let(:current_user) do
          create(:user,
                 member_with_permissions: {
                   project => %i[view_meetings manage_agendas manage_outcomes view_work_packages]
                 })
        end

        it "does not show the new work package option" do
          show_page.visit!
          wait_for_network_idle

          show_page.open_menu(meeting_agenda_item) do
            click_on "Add outcome"
            expect(page).to have_text("Write outcome")
            expect(page).to have_text("Existing work package")
            expect(page).to have_no_text("New work package")
          end
        end
      end
    end
  end

  context "when the work package is from another project" do
    let!(:other_project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
    let!(:other_wp) { create(:work_package, project: other_project, author: user, subject: "Private work package") }
    let!(:role) { create(:project_role, permissions: %w[view_work_packages]) }
    let!(:membership) { create(:member, principal: user, project: other_project, roles: [role]) }
    let!(:other_user) do
      create(:user,
             lastname: "Other",
             member_with_permissions: { project => %i[view_meetings] })
    end
    let!(:outcome) do
      create(:meeting_outcome,
             meeting_agenda_item:,
             work_package: other_wp,
             kind: :work_package)
    end

    it "shows undisclosed message for users without access" do
      show_page.visit!
      wait_for_network_idle

      show_page.in_outcome_component(meeting_agenda_item) do
        expect(page).to have_link("Private work package")
      end

      login_as(other_user)

      show_page.visit!
      wait_for_network_idle

      show_page.in_outcome_component(meeting_agenda_item) do
        expect(page).to have_no_link("Private work package")
        expect(page).to have_text(I18n.t(:label_agenda_item_undisclosed_wp, id: other_wp.id))
      end
    end
  end

  context "when the linked work package is deleted" do
    let!(:work_package_to_delete) { create(:work_package, project:, subject: "To be deleted") }
    let!(:outcome) do
      create(:meeting_outcome,
             meeting_agenda_item:,
             work_package: work_package_to_delete,
             kind: :work_package)
    end

    it "shows deleted work package message after deletion" do
      show_page.visit!
      wait_for_network_idle

      show_page.in_outcome_component(meeting_agenda_item) do
        expect(page).to have_link("To be deleted")
      end

      work_package_to_delete.destroy!

      show_page.visit!
      wait_for_network_idle

      show_page.in_outcome_component(meeting_agenda_item) do
        expect(page).to have_no_link("To be deleted")
        expect(page).to have_text(I18n.t(:label_agenda_item_deleted_wp))
      end
    end
  end

  context "when the meeting is not in progress" do
    let(:state) { :open }
    let(:outcome) do
      create(:meeting_outcome,
             meeting_agenda_item:,
             work_package: work_package1,
             kind: :work_package)
    end

    before do
      outcome
    end

    it "can view work package outcomes but not add or edit them" do
      show_page.visit!
      wait_for_network_idle

      show_page.in_outcome_component(meeting_agenda_item) do
        expect(page).to have_link(work_package1.subject)
      end

      show_page.expect_no_outcome_button
      show_page.expect_no_outcome_actions
    end
  end
end
