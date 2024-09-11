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

RSpec.describe "Group memberships through groups page" do
  shared_let(:admin) { create(:admin) }
  let!(:project) { create(:project, name: "Project 1", identifier: "project1") }

  let!(:peter) { create(:user, firstname: "Peter", lastname: "Pan") }

  let!(:manager) { create(:project_role, name: "Manager") }

  let(:members_page) { Pages::Members.new project.identifier }

  before do
    allow(User).to receive(:current).and_return admin
  end

  shared_examples "errors when adding members" do
    it "adding a role without a principal", :js do
      members_page.visit!
      expect_angular_frontend_initialized
      members_page.add_user! nil, as: "Manager"

      expect(page).to have_text "choose at least one user or group"
    end
  end

  context "creating membership with a user" do
    it_behaves_like "errors when adding members"
  end
end
