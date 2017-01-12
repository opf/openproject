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

RSpec.feature 'Work package create children', js: true, selenium: true do
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
                                     :edit_work_packages,
                                     :manage_subtasks])
  end
  let(:project) { FactoryGirl.create(:project) }
  let(:original_work_package) do
    FactoryGirl.build(:work_package,
                      project: project,
                      assigned_to: assignee,
                      responsible: responsible,
                      fixed_version: version,
                      priority: default_priority,
                      author: author,
                      status: default_status)
  end
  let(:default_priority) do
    FactoryGirl.build(:default_priority)
  end
  let(:default_status) do
    FactoryGirl.build(:default_status)
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
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
    original_work_package.save!
    work_flow.save!
  end

  scenario 'on fullscreen page' do
    original_work_package_page = Pages::FullWorkPackage.new(original_work_package)

    child_work_package_page = original_work_package_page.add_child

    child_work_package_page.expect_heading
    child_work_package_page.expect_current_path

    child_work_package_page.update_attributes Subject: 'Child work package',
                                              Type: 'None'

    child_work_package_page.expect_heading('None')
    child_work_package_page.save!

    expect(page).to have_selector('.notification-box--content',
                                  text: I18n.t('js.notice_successful_create'))

    child_work_package = WorkPackage.order(created_at: 'desc').first

    expect(child_work_package).to_not eql original_work_package

    child_work_package_page = Pages::FullWorkPackage.new(child_work_package, project)

    child_work_package_page.ensure_page_loaded
    child_work_package_page.expect_subject
    child_work_package_page.expect_current_path

    child_work_package_page.expect_parent(original_work_package)
  end

  scenario 'on split screen page' do
    original_work_package_page = Pages::SplitWorkPackage.new(original_work_package, project)

    child_work_package_page = original_work_package_page.add_child

    child_work_package_page.expect_heading
    child_work_package_page.expect_current_path

    child_work_package_page.update_attributes Subject: 'Child work package',
                                              Type: 'None'

    child_work_package_page.expect_heading('None')
    child_work_package_page.save!

    expect(page).to have_selector('.notification-box--content',
                                  text: I18n.t('js.notice_successful_create'))

    child_work_package = WorkPackage.order(created_at: 'desc').first

    expect(child_work_package).to_not eql original_work_package

    child_work_package_page = Pages::SplitWorkPackage.new(child_work_package, project)

    child_work_package_page.ensure_page_loaded
    child_work_package_page.expect_subject
    child_work_package_page.expect_current_path

    child_work_package_page.expect_parent(original_work_package)
  end
end
