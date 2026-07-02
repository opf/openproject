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
require "support/pages/admin/departments"

RSpec.describe "Departments admin",
               :js do
  shared_let(:admin) { create(:admin) }

  let(:departments_page) { Pages::Admin::Departments.new }

  current_user { admin }

  describe "empty state" do
    it "shows the global blankslate when no departments exist" do
      departments_page.visit!

      departments_page.expect_empty_state
    end
  end

  describe "viewing departments" do
    shared_let(:parent) { create(:department, lastname: "Engineering") }
    shared_let(:child) { create(:department, lastname: "Backend", parent: parent) }
    shared_let(:sibling) { create(:department, lastname: "Frontend", parent: parent) }

    it "lists child departments and supports tree navigation" do
      departments_page.visit_department(parent)

      departments_page.expect_department_listed("Backend")
      departments_page.expect_department_listed("Frontend")
      departments_page.expect_breadcrumbs(Setting.organization_name.presence || I18n.t("setting_organization_name"),
                                          "Engineering")

      departments_page.tree_view.click_node("Backend")

      departments_page.expect_breadcrumbs(Setting.organization_name.presence || I18n.t("setting_organization_name"),
                                          "Engineering",
                                          "Backend")
      departments_page.tree_view.should_have_active_item("Backend")
    end

    it "shows the detail blankslate for an empty department" do
      departments_page.visit_department(child)

      departments_page.expect_department_empty_state
    end
  end

  describe "adding a department" do
    shared_let(:parent) { create(:department, lastname: "Engineering") }

    it "creates a sub-department" do
      departments_page.visit_department(parent)

      departments_page.add_department("Backend")

      expect_flash(message: I18n.t("departments.flash.department_created"), type: :success)
      departments_page.expect_department_listed("Backend")
    end
  end

  describe "canceling add department" do
    shared_let(:department) { create(:department, lastname: "Engineering") }

    it "hides the form on cancel" do
      departments_page.visit_department(department)

      wait_for_turbo_frame { departments_page.click_add_department }

      expect(page).to have_field(I18n.t("departments.add_department_form.name_placeholder"))

      departments_page.cancel_add_department

      expect(page).to have_no_field(I18n.t("departments.add_department_form.name_placeholder"))
    end
  end

  describe "adding a user" do
    shared_let(:department) { create(:department, lastname: "Engineering") }
    shared_let(:user) { create(:user, firstname: "Jane", lastname: "Doe") }

    it "adds the user to the department" do
      departments_page.visit_department(department)

      departments_page.add_user("Jane Doe")

      expect_flash(message: I18n.t("departments.flash.user_added"), type: :success)
      departments_page.expect_user_listed("Jane Doe")
    end
  end

  describe "canceling add user" do
    shared_let(:department) { create(:department, lastname: "Engineering") }

    it "hides the form on cancel" do
      departments_page.visit_department(department)

      wait_for_turbo_frame { departments_page.click_add_user }

      expect(page).to have_css("opce-user-autocompleter")

      departments_page.cancel_add_user

      expect(page).to have_no_css("opce-user-autocompleter")
    end
  end

  describe "moving a user between departments" do
    shared_let(:dept_a) { create(:department, lastname: "Department A") }
    shared_let(:dept_b) { create(:department, lastname: "Department B") }
    shared_let(:user) { create(:user, firstname: "Jane", lastname: "Doe") }

    before do
      Departments::AddUserService
        .new(dept_a, user: admin)
        .call(user_id: user.id)
    end

    it "shows a confirmation dialog and moves the user" do
      departments_page.visit_department(dept_b)

      wait_for_turbo_frame { departments_page.click_add_user }

      departments_page.select_user_in_autocompleter("Jane Doe")
      departments_page.submit_add_form

      # The move user dialog should appear
      dialog_id = Admin::Departments::MoveUserDialogComponent::DIALOG_ID
      expect(page).to have_css("##{dialog_id}", wait: 10)

      within("##{dialog_id}") do
        click_on I18n.t("departments.move_user_dialog.confirm")
      end

      expect_flash(message: I18n.t("departments.flash.user_added"), type: :success)
      departments_page.expect_user_listed("Jane Doe")
    end
  end

  describe "removing a user" do
    shared_let(:department) { create(:department, lastname: "Engineering") }
    shared_let(:user) { create(:user, firstname: "Jane", lastname: "Doe") }

    before do
      Departments::AddUserService
        .new(department, user: admin)
        .call(user_id: user.id)
    end

    it "removes the user from the department after confirmation" do
      departments_page.visit_department(department)

      departments_page.expect_user_listed("Jane Doe")

      departments_page.remove_user("Jane Doe")

      expect_flash(message: I18n.t("departments.flash.user_removed"), type: :success)
      departments_page.expect_no_user_listed("Jane Doe")
    end
  end

  describe "organization name" do
    before do
      Setting.organization_name = "Acme Corp"
    end

    it "displays the organization name in the breadcrumbs" do
      departments_page.visit!

      departments_page.expect_breadcrumbs("Acme Corp")
    end

    it "can be edited inline" do
      departments_page.visit!

      departments_page.expect_organization_name("Acme Corp")

      departments_page.edit_organization_name("New Corp Name")

      departments_page.expect_organization_name("New Corp Name")
      departments_page.expect_no_organization_name_form
      expect(Setting.organization_name).to eq("New Corp Name")
    end

    it "can cancel editing" do
      departments_page.visit!

      departments_page.click_edit_organization_name

      departments_page.expect_organization_name_form

      departments_page.cancel_edit_organization_name

      departments_page.expect_no_organization_name_form
      departments_page.expect_organization_name("Acme Corp")
    end
  end
end
