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

RSpec.describe "Dedicated custom field admin pages" do
  shared_let(:admin) { create(:admin) }

  before { login_as admin }

  shared_examples "a dedicated custom field page" do |factory:, route:, section:, page_title:|
    let(:url_helpers) { Rails.application.routes.url_helpers }
    let(:index_path) { url_helpers.public_send(:"#{route}s_path") }
    let(:custom_field) { create(factory, name: "Existing field") }

    it "links to the page from its admin section menu" do
      visit index_path

      within "#menu-sidebar" do
        expect(page).to have_link(page_title, href: %r{#{Regexp.escape(index_path)}\z})
      end
    end

    it "nests the page under its section in the breadcrumb" do
      visit url_helpers.public_send(:"edit_#{route}_path", custom_field)

      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link("Administration")
        expect(page).to have_link(section)
        expect(page).to have_link(page_title)
        expect(page).to have_text(custom_field.name)
      end
    end
  end

  describe "work package custom fields" do
    it_behaves_like "a dedicated custom field page",
                    factory: :work_package_custom_field,
                    route: "admin_settings_work_package_custom_field",
                    section: "Work packages",
                    page_title: "Custom fields"
  end

  describe "version custom fields" do
    it_behaves_like "a dedicated custom field page",
                    factory: :version_custom_field,
                    route: "admin_settings_version_custom_field",
                    section: "Work packages",
                    page_title: "Version custom fields"
  end

  describe "group custom fields" do
    it_behaves_like "a dedicated custom field page",
                    factory: :group_custom_field,
                    route: "admin_settings_group_custom_field",
                    section: "Users and permissions",
                    page_title: "Group attributes"
  end

  describe "time entry custom fields" do
    it_behaves_like "a dedicated custom field page",
                    factory: :time_entry_custom_field,
                    route: "admin_settings_time_entry_custom_field",
                    section: "Time and costs",
                    page_title: "Time entry custom fields"
  end
end
