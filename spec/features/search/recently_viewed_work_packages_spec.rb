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

RSpec.describe "Recently viewed work packages",
               :js,
               with_settings: { login_required: false } do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:global_search) { Components::GlobalSearch.new }

  def recently_viewed_header_text
    I18n.t("js.global_search.recently_viewed", raise: true).upcase
  end

  context "when no work packages have been viewed" do
    it "displays nothing after clicking in the global search bar" do
      visit home_path

      global_search.click_input
      expect(global_search.dropdown).to be_visible
      expect(global_search.dropdown).to have_no_text(recently_viewed_header_text)
    end
  end

  context "when a work package has been viewed" do
    shared_let(:project) { create(:public_project) }
    shared_let(:anonymous_role) { create(:anonymous_role, permissions: %i[view_project view_work_packages]) }
    shared_let(:work_package) { create(:work_package, project:) }

    before do
      work_package_page = Pages::FullWorkPackage.new(work_package)
      work_package_page.visit!
      work_package_page.ensure_loaded
    end

    it "is displayed as result after clicking in the global search bar" do
      visit home_path
      global_search.click_input

      # header is displayed
      expect(global_search.dropdown).to be_visible
      expect(global_search.dropdown).to have_text(recently_viewed_header_text)

      # work package is displayed and marked
      global_search.expect_work_package_option(work_package)
      global_search.expect_work_package_marked(work_package)

      # clicking goes to the work package view
      global_search.click_work_package(work_package)
      expect(page)
        .to have_css(".subject", text: work_package.subject)
      expect(page)
        .to have_current_path project_work_package_path(work_package.project, work_package, state: "activity")
    end

    it "is not shown after typing something in the global search bar" do
      visit home_path

      # typing some words hides the work package
      global_search.search("random text")

      # recently viewed items not shown
      expect(global_search.dropdown).to have_no_text(recently_viewed_header_text)
      global_search.expect_no_work_package_option(work_package)
    end
  end
end
