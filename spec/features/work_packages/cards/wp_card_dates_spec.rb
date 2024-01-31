#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe 'Showing dates on WP cards',
               :js,
               :with_cuprite,
               with_settings: { date_format: '%Y-%m-%d' } do
  let(:manager_role) do
    create(:project_role, permissions: %i[view_work_packages edit_work_packages])
  end
  let(:manager) do
    create(:user,
           firstname: 'Manager',
           lastname: 'Guy',
           member_with_roles: { project => manager_role })
  end
  let(:status1) { create(:status) }
  let(:status2) { create(:status) }

  let(:type) { create(:type) }
  let(:type_milestone) { create(:type_milestone) }
  let!(:project) { create(:project, types: [type, type_milestone]) }
  let!(:empty) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           start_date: nil,
           due_date: nil,
           subject: 'Empty dates')
  end

  let!(:start) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           start_date: '2024-01-22',
           due_date: nil,
           subject: 'Start only')
  end

  let!(:due) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           due_date: '2024-01-22',
           start_date: nil,
           subject: 'Due only')
  end

  let!(:both) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           start_date: '2024-01-20',
           due_date: '2024-01-22',
           subject: 'Due only')
  end

  let!(:milestone) do
    create(:work_package,
           project:,
           type: type_milestone,
           status: status1,
           due_date: '2024-01-22',
           subject: 'Milestone')
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:wp_card_view) { Pages::WorkPackageCards.new(project) }
  let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }

  before do
    login_as(manager)

    wp_table.visit!
    display_representation.switch_to_card_layout
  end

  it 'shows the correct dates' do
    empty_card = wp_card_view.card(empty)
    expect(empty_card).to have_css('.op-wp-single-card--content-dates', text: '', exact_text: true)

    start_only_card = wp_card_view.card(start)
    expect(start_only_card).to have_css('.op-wp-single-card--content-dates', text: 'Jan 22, 2024 -', exact_text: true)

    due_only_card = wp_card_view.card(due)
    expect(due_only_card).to have_css('.op-wp-single-card--content-dates', text: '- Jan 22, 2024', exact_text: true)

    both_card = wp_card_view.card(both)
    expect(both_card).to have_css('.op-wp-single-card--content-dates', text: 'Jan 20, 2024 - Jan 22, 2024', exact_text: true)

    milestone_card = wp_card_view.card(milestone)
    expect(milestone_card).to have_css('.op-wp-single-card--content-dates', text: 'Jan 22, 2024', exact_text: true)
  end
end
