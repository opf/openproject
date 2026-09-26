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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package CSV import entry point", :js do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }

  shared_let(:work_package) { create(:work_package, project:, type:) }

  let(:work_packages_page) { Pages::WorkPackagesTable.new(project) }
  let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }
  let(:entry) { /#{Regexp.escape(I18n.t('js.work_packages.create.import'))}/i }

  def open_create_menu
    work_packages_page.visit!
    work_packages_page.expect_type_available_for_create(type)
  end

  # The full view loads no work package collection, so the dropdown authorises against the
  # single work package it shows.
  def open_create_menu_on_the_full_view
    full_view.visit!
    full_view.ensure_page_loaded
    find(".add-work-package:not([disabled])", wait: 10).click
  end

  before { login_as user }

  context "as a member holding the permission" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %i[view_work_packages add_work_packages import_work_packages]
             })
    end

    it "offers the import beside the types, and opens the page" do
      open_create_menu

      find("#types-context-menu a.menu-item", text: entry).click

      expect(page).to have_current_path(import_project_work_packages_path(project))
      expect(page).to have_text(I18n.t("work_packages.import.title"))
      expect(page).to have_text(I18n.t("work_packages.import.guidance.title"))
    end
  end

  context "as a member holding the permission, on a single work package" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %i[view_work_packages add_work_packages import_work_packages]
             })
    end

    it "offers the import beside the types, and opens the page" do
      open_create_menu_on_the_full_view

      find("#types-context-menu a.menu-item", text: entry).click

      expect(page).to have_current_path(import_project_work_packages_path(project))
      expect(page).to have_text(I18n.t("work_packages.import.title"))
    end
  end

  context "as a member without the permission, on a single work package" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] })
    end

    it "leaves the entry out" do
      open_create_menu_on_the_full_view

      expect(page).to have_no_css("#types-context-menu", text: entry)
    end
  end

  context "as a member without the permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] })
    end

    it "leaves the entry out" do
      open_create_menu

      expect(page).to have_no_css("#types-context-menu", text: entry)
    end
  end
end
