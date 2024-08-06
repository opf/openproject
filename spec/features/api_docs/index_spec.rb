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

RSpec.describe "REST API docs index page", :js do
  subject(:visit_docs_page) { visit(api_docs_path) }

  context "with anonymous user" do
    it "displays the login form" do
      visit_docs_page

      expect(page).to have_current_path(signin_path(back_url: api_docs_url))
    end
  end

  context "with authenticated user" do
    current_user { create(:user) }

    it "displays the docs rendered by openapi-explorer" do
      visit_docs_page

      # web component are harder to test with capybara
      expect(find("openapi-explorer").shadow_root).to have_css("#api-title", text: "OpenProject API V3 (Stable)")
    end

    context "when APIv3 documentation is disabled (from Administration > API > Enable docs page)",
            with_settings: { apiv3_docs_enabled: false } do
      it "renders a 404" do
        visit_docs_page

        expect(page).to have_text "Error 404"
      end
    end
  end
end
