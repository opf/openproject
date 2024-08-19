#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe "Work package timeline labels",
               :js,
               :selenium,
               with_settings: { date_format: "%Y-%m-%d" } do
  let(:user) { create(:admin) }
  let(:today) { Time.zone.today }
  let(:tomorrow) { Time.zone.tomorrow }
  let(:future) { Time.zone.today + 5 }
  let(:work_package) do
    create(:work_package,
           project:,
           type:,
           assigned_to: user,
           start_date: today,
           due_date: tomorrow,
           subject: "My subject",
           custom_field_values: { custom_field.id => custom_value_for("onions") })
  end
  let(:milestone_work_package) do
    create(:work_package,
           project:,
           type: milestone_type,
           start_date: future,
           due_date: future,
           subject: "My milestone")
  end
  let(:type) { create(:type_bug) }
  let(:milestone_type) { create(:type, is_milestone: true) }

  let(:project) { create(:project, types: [type, milestone_type], enabled_module_names: %i[work_package_tracking gantt]) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
  let(:config_modal) { Components::Timelines::ConfigurationModal.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(project) }

  let(:custom_field) do
    create(
      :list_wp_custom_field,
      name: "Ingredients",
      multi_value: true,
      types: [type],
      projects: [project],
      possible_values: ["ham", "onions", "pineapple", "mushrooms"]
    )
  end

  let!(:query_tl) do
    query = build(:query_with_view_gantt, user:, project:)
    query.filters.clear
    query.timeline_visible = true
    query.name = "Query with Timeline"

    query.save!

    query
  end

  def custom_value_for(str)
    custom_field.custom_options.find { |co| co.value == str }.try(:id)
  end

  before do
    custom_field
    milestone_work_package
    work_package
    login_as(user)

    wp_timeline.visit_query(query_tl)
    wp_timeline.expect_timeline!
  end

  it "shows and allows to configure labels" do
    # Check default labels (bar type)
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: nil,
                      right: nil,
                      farRight: "My subject"

    row.expect_hovered_labels left: today.iso8601, right: tomorrow.iso8601

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: nil,
                      right: nil,
                      farRight: "My milestone"
    row.expect_hovered_labels left: nil, right: future.iso8601

    # Modify label configuration
    config_modal.open!
    config_modal.expect_labels! left: "(none)",
                                right: "(none)",
                                farRight: "Subject"

    config_modal.update_labels left: "Assignee",
                               right: "Type",
                               farRight: "Status"

    # Check overridden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: user.name,
                      right: type.name.upcase,
                      farRight: work_package.status.name

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: "-",
                      right: milestone_type.name.upcase,
                      farRight: milestone_work_package.status.name

    # Save the query
    settings_menu.open_and_save_query_as "changed labels"
    wp_timeline.expect_title "changed labels"

    # Check the query
    query = Query.last
    expect(query.timeline_labels).to eq left: "assignee",
                                        right: "type",
                                        farRight: "status"

    # Revisit page
    wp_timeline.visit_query query
    wp_timeline.expect_work_package_listed(work_package, milestone_work_package)
    wp_timeline.expect_timeline!(open: true)

    # Check overridden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: user.name,
                      right: type.name.upcase,
                      farRight: work_package.status.name

    # Check overridden labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: "-",
                      right: milestone_type.name.upcase,
                      farRight: milestone_work_package.status.name

    # Set labels to start|due|subject
    config_modal.open!
    config_modal.expect_labels! left: "Assignee",
                                right: "Type",
                                farRight: "Status"

    config_modal.update_labels left: "Start date",
                               right: "Finish date",
                               farRight: "Subject"

    # Check overridden labels
    row = wp_timeline.timeline_row work_package.id
    row.expect_labels left: today.iso8601,
                      right: tomorrow.iso8601,
                      farRight: work_package.subject

    # Check default labels (milestone)
    row = wp_timeline.timeline_row milestone_work_package.id
    row.expect_labels left: nil,
                      right: future.iso8601,
                      farRight: milestone_work_package.subject
  end
end
