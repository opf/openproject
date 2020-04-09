#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

feature 'group memberships through groups page', type: :feature, js: true do
  using_shared_fixtures :admin
  let!(:project) { FactoryBot.create :project, name: 'Project 1', identifier: 'project1' }

  let!(:peter) do
    FactoryBot.create :user,
                       firstname: 'Peter',
                       lastname: 'Pan',
                       mail: 'foo@example.org',
                       member_in_project: project,
                       member_through_role: role

  end

  let!(:hannibal) do
    FactoryBot.create :user,
                       firstname: 'Pan',
                       lastname: 'Hannibal',
                       mail: 'foo@example.com',
                       member_in_project: project,
                       member_through_role: role

  end
  let(:role) { FactoryBot.create(:role, permissions: %i(add_work_packages)) }
  let(:members_page) { Pages::Members.new project.identifier }

  before do
    login_as(admin)
    members_page.visit!
    expect_angular_frontend_initialized
  end

  scenario 'filters users based on some name attribute' do
    members_page.open_filters!

    members_page.search_for_name 'pan'
    members_page.find_mail hannibal.mail
    members_page.find_mail peter.mail

    members_page.search_for_name '@example'
    members_page.find_mail hannibal.mail
    members_page.find_mail peter.mail

    members_page.search_for_name '@example.org'
    members_page.find_mail peter.mail
    expect(page).to have_no_selector('td.mail', text: hannibal.mail)
  end
end
