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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'Only see your own rates', type: :feature, js: true do
  let(:project) { work_package.project }
  let(:user) { FactoryBot.create :user,
                                  member_in_project: project,
                                  member_through_role: role }
  let(:role) { FactoryBot.create :role, permissions: [:view_work_packages,
                                                       :delete_work_packages,
                                                       :edit_cost_entries,
                                                       :view_cost_entries] }
  let(:work_package) {FactoryBot.create :work_package }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }
  let(:cost_type) {
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate, cost_type: type,
                                   rate: 7.00
    type
  }
  let(:budget) do
    FactoryBot.create(:cost_object, project: project)
  end
  let(:other_work_package) {FactoryBot.create :work_package, project: project, cost_object: budget }
  let(:cost_entry) { FactoryBot.create :cost_entry, work_package: work_package,
                                                     project: project,
                                                     units: 2.00,
                                                     cost_type: cost_type,
                                                     user: user }

  it 'allows to move the time entry to a different work package' do
    allow(User).to receive(:current).and_return(user)

    work_package
    other_work_package
    cost_entry

    wp_page = Pages::FullWorkPackage.new(work_package)
    wp_page.visit!

    find('#action-show-more-dropdown-menu').click();

    click_link(I18n.t('js.button_delete'))

    destroy_modal.expect_listed(work_package)
    destroy_modal.confirm_deletion

    choose 'to_do_action_reassign'
    sleep 1
    fill_in 'to_do_reassign_to_id', :with => other_work_package.id

    click_button(I18n.t('button_delete'))

    other_wp_page = Pages::FullWorkPackage.new(other_work_package)
    other_wp_page.visit!

    wp_page.expect_attributes costs_by_type: '2 Translations'
  end
end
