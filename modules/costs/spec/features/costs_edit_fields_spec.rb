#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Work Package cost fields', type: :feature, js: true do
  let(:type_task) { FactoryBot.create(:type_task) }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let!(:project) {
    FactoryBot.create(:project, types: [type_task])
  }
  let(:user) { FactoryBot.create :admin }
  let(:budget) { FactoryBot.create :cost_object, author: user, project: project }

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:split_create) { ::Pages::SplitWorkPackageCreate.new(project: project) }

  before do
    budget
    login_as(user)
  end

  it 'does not show read-only fields' do
    wp_table.visit!
    wp_table.expect_no_work_package_listed

    split_create.click_create_wp_button type_task.name
    split_create.expect_fully_loaded

    expect(page).to have_selector('.wp-edit-field--container.costObject')
    expect(page).to have_no_selector('.wp-edit-field--container.laborCosts')
    expect(page).to have_no_selector('.wp-edit-field--container.materialCosts')
    expect(page).to have_no_selector('.wp-edit-field--container.overallCosts')

    field = split_create.edit_field(:costObject)
    field.openSelectField
    field.set_value budget.name
  end
end
