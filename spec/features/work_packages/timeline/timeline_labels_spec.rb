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

RSpec.feature 'Work package timeline labels',
              with_settings: { date_format: '%Y-%m-%d' },
              js: true,
              selenium: true do
  let(:user) { FactoryBot.create(:admin) }
  let(:type) { FactoryBot.create(:type_bug) }
  let(:milestone_type) { FactoryBot.create(:type, is_milestone: true) }

  let(:project) { FactoryBot.create(:project, types: [type, milestone_type]) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
  let(:config_modal) { Components::Timelines::ConfigurationModal.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

  let(:custom_field) do
    FactoryBot.create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  let(:today) { Date.today.iso8601 }
  let(:tomorrow) { Date.tomorrow.iso8601  }
  let(:future) { (Date.today + 5).iso8601  }

  let(:work_package) do
    FactoryBot.create :work_package,
                       project: project,
                       type: type,
                       assigned_to: user,
                       start_date: today,
                       due_date: tomorrow,
                       subject: 'My subject',
                       custom_field_values: { custom_field.id => custom_value_for('onions') }
  end

  let(:milestone_work_package) do
    FactoryBot.create :work_package,
                       project: project,
                       type: milestone_type,
                       start_date: future,
                       due_date: future,
                       subject: 'My milestone'
  end

  before do
    custom_field
    milestone_work_package
    work_package
    login_as(user)

    wp_timeline.visit!
    wp_timeline.expect_timeline! open: false
    wp_timeline.toggle_timeline
  end

  it 'shows and allows to configure labels' do
    # Check default labels (bar type)
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: nil,
                      right: nil,
                      farRight: 'My subject'

    row.expect_hovered_labels left: today, right: tomorrow

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: nil,
                      right: nil,
                      farRight: 'My milestone'
    row.expect_hovered_labels left: nil, right: future

    # Modify label configuration
    config_modal.open!
    config_modal.expect_labels! left: '(none)',
                                right: '(none)',
                                farRight: 'Subject'

    config_modal.update_labels left: 'Assignee',
                               right: 'Type',
                               farRight: 'Status'

    # Check overriden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: user.name,
                      right: type.name,
                      farRight: work_package.status.name

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: '-',
                      right: milestone_type.name,
                      farRight: milestone_work_package.status.name

    # Save the query
    settings_menu.open_and_save_query 'changed labels'
    wp_timeline.expect_title 'changed labels'

    # Check the query
    query = Query.last
    expect(query.timeline_labels).to eq 'left' => 'assignee',
                                        'right' => 'type',
                                        'farRight' => 'status'

    # Revisit page
    wp_timeline.visit_query query
    wp_timeline.expect_work_package_listed(work_package, milestone_work_package)
    wp_timeline.expect_timeline!(open: true)

    # Check overridden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: user.name,
                      right: type.name,
                      farRight: work_package.status.name

    # Check overridden labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: '-',
                      right: milestone_type.name,
                      farRight: milestone_work_package.status.name

    # Set labels to start|due|subject
    config_modal.open!
    config_modal.expect_labels! left: 'Assignee',
                                right: 'Type',
                                farRight: 'Status'

    config_modal.update_labels left: 'Start date',
                               right: 'Finish date',
                               farRight: 'Subject'

    # Check overriden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: today,
                      right: tomorrow,
                      farRight: work_package.subject

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: nil,
                      right: future,
                      farRight: milestone_work_package.subject

  end
end
