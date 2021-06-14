#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Work Package budget fields', type: :feature, js: true do
  let(:type_task) { FactoryBot.create(:type_task) }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let!(:project) { FactoryBot.create(:project, types: [type_task]) }
  let(:role) { FactoryBot.create(:role, permissions: %i[add_work_packages view_work_packages view_budgets]) }
  let!(:budget) { FactoryBot.create :budget, author: current_user, project: project }
  let!(:workflow) { FactoryBot.create(:workflow, type: type_task, old_status: status, role: role) }

  let(:create_page) { ::Pages::FullWorkPackageCreate.new(project: project) }
  let(:view_page) { ::Pages::FullWorkPackage.new(project: project) }

  current_user do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  it 'does not show read-only fields and allows setting the budget' do
    create_page.visit!

    expect(page).to have_selector('.inline-edit--container.budget')
    expect(page).to have_no_selector('.inline-edit--container.laborCosts')
    expect(page).to have_no_selector('.inline-edit--container.materialCosts')
    expect(page).to have_no_selector('.inline-edit--container.overallCosts')

    field = create_page.edit_field(:budget)
    field.set_value budget.name
    page.find('.ng-dropdown-panel .ng-option', text: budget.name).click

    field = create_page.edit_field(:subject)
    field.set_value 'Some subject'

    create_page.save!

    view_page.expect_notification(message: "Successful creation.")

    view_page.edit_field(:budget).expect_display_value budget.name
  end
end
