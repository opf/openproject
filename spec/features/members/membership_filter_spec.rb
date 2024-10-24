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

RSpec.describe "group memberships through groups page", :js do
  shared_let(:admin) { create(:admin) }
  let!(:project) { create(:project, name: "Project 1", identifier: "project1") }

  let!(:peter) do
    create(:user,
           firstname: "Peter",
           lastname: "Pan",
           mail: "foo@example.org",
           member_with_roles: { project => role })
  end

  let!(:hannibal) do
    create(:user,
           firstname: "Pan",
           lastname: "Hannibal",
           mail: "foo@example.com",
           member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions: %i(add_work_packages view_members)) }
  let(:members_page) { Pages::Members.new project.identifier }
  let(:user_to_login) { admin }
  let(:standard_global_role) { nil }

  before do
    standard_global_role
    login_as user_to_login
    members_page.visit!
    expect_angular_frontend_initialized
  end

  shared_examples "it filters users" do
    it "filters users based on some name attribute" do
      members_page.open_filters!

      members_page.search_for_name "pan"
      members_page.find_user "Pan Hannibal"
      expect(page).to have_no_css("td.mail", text: hannibal.mail)
      members_page.find_user "Peter Pan"
      members_page.find_mail peter.mail

      members_page.search_for_name "@example"
      members_page.find_user "Pan Hannibal"
      expect(page).to have_no_css("td.mail", text: hannibal.mail)
      members_page.find_user "Peter Pan"
      members_page.find_mail peter.mail

      members_page.search_for_name "@example.org"
      members_page.find_user "Peter Pan"
      members_page.find_mail peter.mail
      expect(page).to have_no_css("td.mail", text: hannibal.mail)
    end
  end

  it_behaves_like "it filters users"

  context "with a user" do
    let(:user_to_login) { peter }

    context "without view_user_email permission" do
      it "filters users based on some name attribute" do
        members_page.open_filters!

        members_page.search_for_name "pan"
        members_page.find_user "Pan Hannibal"
        expect(page).to have_no_css("td.mail", text: hannibal.mail)
        members_page.find_user "Peter Pan"
        members_page.find_mail peter.mail
        members_page.search_for_name "@example"
        # Does not find other users based on their email address
        expect(page).to have_no_css("tr", text: "Pan Hannibal")
        expect(page).to have_no_css("td.mail", text: hannibal.mail)
        expect(page).to have_no_css("tr", text: "Peter Pan")
        expect(page).to have_no_css("td.mail", text: peter.mail)

        members_page.search_for_name "@example.org"
        # Does not find other users based on their email address
        expect(page).to have_no_css("tr", text: "Pan Hannibal")
        expect(page).to have_no_css("td.mail", text: hannibal.mail)
        expect(page).to have_no_css("tr", text: "Peter Pan")
        expect(page).to have_no_css("td.mail", text: peter.mail)
      end
    end

    context "with view_user_email permission" do
      let(:standard_global_role) { create :standard_global_role }

      it_behaves_like "it filters users"
    end
  end
end
