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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Breadcrumbs (#63777)", :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  before do
    login_as user
  end

  context "when being on an index page which is not the home screen" do
    it "does not create a loop in the mobile back links" do
      visit projects_path

      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link href: "#", text: "Active projects", aria: { current: "page" }
        expect(page).to have_link href: "/projects", text: "Projects"
      end
    end
  end

  context "when being on an non-index page" do
    it "does show the index page as mobile back link" do
      visit projects_path({ query_id: "my" })

      within ".PageHeader-breadcrumbs" do
        expect(page).to have_link href: "#", text: "My projects", aria: { current: "page" }
        expect(page).to have_link href: "/projects", text: "Projects"
      end

      expect(page).to have_link href: "/projects", text: "Projects", class: "PageHeader-parentLink", visible: :hidden
    end
  end

  context "when being on the home screen" do
    it "does not show breadcrumbs" do
      visit "/"
      expect(page).to have_css ".PageHeader--noBreadcrumb"
    end
  end
end
