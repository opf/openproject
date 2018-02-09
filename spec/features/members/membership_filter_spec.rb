#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
  let!(:project) { FactoryGirl.create :project, name: 'Project 1', identifier: 'project1' }

  let(:admin)     { FactoryGirl.create :admin }
  let!(:peter) do
    FactoryGirl.create :user,
                       firstname: 'Peter',
                       lastname: 'Pan',
                       mail: 'foo@example.org',
                       member_in_project: project,
                       member_through_role: role

  end

  let!(:hannibal) do
    FactoryGirl.create :user,
                       firstname: 'Pan',
                       lastname: 'Hannibal',
                       mail: 'foo@example.com',
                       member_in_project: project,
                       member_through_role: role

  end
  let(:role) { FactoryGirl.create(:role, permissions: %i(add_work_packages)) }
  let(:members_page) { Pages::Members.new project.identifier }

  before do
    login_as(admin)
  end

  scenario 'filters users based on some name attribute' do
    members_page.visit!
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
