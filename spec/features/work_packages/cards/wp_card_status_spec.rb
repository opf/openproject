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

describe 'Update status from WP card', type: :feature, js: true do
  let(:manager_role) do
    FactoryBot.create :role, permissions: %i[view_work_packages edit_work_packages]
  end
  let(:manager) do
    FactoryBot.create :user,
                      firstname: 'Manager',
                      lastname: 'Guy',
                      member_in_project: project,
                      member_through_role: manager_role
  end
  let(:status1) { FactoryBot.create :status }
  let(:status2) { FactoryBot.create :status }

  let(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create(:project, types: [type]) }
  let!(:work_package) {
    FactoryBot.create(:work_package,
                      project: project,
                      type: type,
                      status: status1,
                      subject: 'Foobar')
  }

  let!(:workflow) do
    FactoryBot.create :workflow,
                      type_id: type.id,
                      old_status: status1,
                      new_status: status2,
                      role: manager_role
  end

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:wp_card_view) { ::Pages::WorkPackageCards.new(project) }
  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }

  before do
    login_as(manager)

    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)

    display_representation.switch_to_card_layout
  end

  it 'can update the status through the button' do
    status_button = wp_card_view.status_button(work_package)
    status_button.update status2.name

    wp_card_view.expect_and_dismiss_notification message: 'Successful update.'
    status_button.expect_text status2.name

    work_package.reload
    expect(work_package.status).to eq(status2)
  end
end
