#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

RSpec.feature 'Work package copy', js: true, selenium: true do
  let(:user) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: create_role)
  end
  let(:work_flow) do
    FactoryGirl.create(:workflow,
                       role: create_role,
                       type_id: original_work_package.type_id,
                       old_status: original_work_package.status,
                       new_status: FactoryGirl.create(:status))
  end

  let(:create_role) do
    FactoryGirl.create(:role,
                       permissions: [:view_work_packages,
                                     :add_work_packages,
                                     :edit_work_packages])
  end
  let(:type) { FactoryGirl.create(:type) }
  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:original_work_package) do
    FactoryGirl.build(:work_package,
                      project: project,
                      assigned_to: assignee,
                      responsible: responsible,
                      fixed_version: version,
                      type: type,
                      author: author)
  end
  let(:role) { FactoryGirl.build(:role, permissions: [:view_work_packages]) }
  let(:assignee) do
    FactoryGirl.build(:user,
                      firstname: 'An',
                      lastname: 'assignee',
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:responsible) do
    FactoryGirl.build(:user,
                      firstname: 'The',
                      lastname: 'responsible',
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:author) do
    FactoryGirl.build(:user,
                      firstname: 'The',
                      lastname: 'author',
                      member_in_project: project,
                      member_through_role: role)
  end
  let(:version) do
    FactoryGirl.build(:version,
                      project: project)
  end

  before do
    login_as(user)
    original_work_package.save!
    work_flow.save!
  end

  scenario 'on fullscreen page' do
    original_work_package_page = Pages::FullWorkPackage.new(original_work_package, project)
    to_copy_work_package_page = original_work_package_page.visit_copy!

    to_copy_work_package_page.expect_current_path
    to_copy_work_package_page.expect_fully_loaded

    to_copy_work_package_page.update_attributes Description: 'Copied WP Description'
    to_copy_work_package_page.save!

    expect(page).to have_selector('.notification-box--content',
                                  text: I18n.t('js.notice_successful_create'))

    copied_work_package = WorkPackage.order(created_at: 'desc').first

    expect(copied_work_package).to_not eql original_work_package

    work_package_page = Pages::FullWorkPackage.new(copied_work_package, project)

    work_package_page.ensure_page_loaded
    work_package_page.expect_attributes Subject: original_work_package.subject,
                                        Description: 'Copied WP Description',
                                        Version: original_work_package.fixed_version,
                                        Priority: original_work_package.priority,
                                        Assignee: original_work_package.assigned_to,
                                        Responsible: original_work_package.responsible

    work_package_page.expect_activity user, number: 1
    work_package_page.expect_current_path
  end

  scenario 'on split screen page' do
    original_work_package_page = Pages::SplitWorkPackage.new(original_work_package, project)
    to_copy_work_package_page = original_work_package_page.visit_copy!

    to_copy_work_package_page.expect_current_path
    to_copy_work_package_page.expect_fully_loaded

    to_copy_work_package_page.update_attributes Description: 'Copied WP Description'
    to_copy_work_package_page.save!

    expect(page).to have_selector('.notification-box--content',
                                  text: I18n.t('js.notice_successful_create'))

    copied_work_package = WorkPackage.order(created_at: 'desc').first

    expect(copied_work_package).to_not eql original_work_package

    work_package_page = Pages::SplitWorkPackage.new(copied_work_package, project)

    work_package_page.ensure_page_loaded
    work_package_page.expect_attributes Subject: original_work_package.subject,
                                        Description: 'Copied WP Description',
                                        Version: original_work_package.fixed_version,
                                        Priority: original_work_package.priority,
                                        Assignee: original_work_package.assigned_to,
                                        Responsible: original_work_package.responsible

    work_package_page.expect_activity user, number: 1
    work_package_page.expect_current_path
  end
end
