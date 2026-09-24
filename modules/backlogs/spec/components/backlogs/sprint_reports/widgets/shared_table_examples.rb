# frozen_string_literal: true

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

require "rails_helper"

RSpec.shared_context "with a sprint report work package table" do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_sprints] }) }

  let(:start_date) { 7.days.ago }
  let(:finish_date) { 7.days.from_now }
  let(:started_at) { 5.days.ago }
  let(:completed_at) { nil }
  let(:sprint) { build_stubbed(:sprint, project:, start_date:, finish_date:, started_at:, completed_at:) }
  let(:breakdown) do
    SprintWorkPackageBreakdown.new(sprint:, project:).tap do |breakdown|
      allow(breakdown).to receive_messages(breakdown_stubs)
    end
  end

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(sprint, project, breakdown)) }

  let(:rendered_html) { rendered_component.to_html }
  let(:table_element) { rendered_component.at("opce-embedded-work-package-table") }
  let(:query_props) { JSON.parse(table_element["data-query-props"]) }

  let(:expected_extra_query_props) { {} }

  shared_examples "renders the sprint report widget box" do
    it "renders a full width widget box" do
      expect(rendered_component).to have_css("div.widget-box.widget-box_full-width.op-sprint-report-wp-table")
    end

    it "renders it with correct header" do
      expect(rendered_component).to have_element(:h3, text: widget_name)
    end
  end

  shared_examples "renders a blankslate" do |description:, icon: :table, heading: "No work packages to display"|
    include_examples "renders the sprint report widget box"

    it "renders a blankslate", :aggregate_failures do
      expect(rendered_component).to have_no_css("opce-embedded-work-package-table")
      expect(rendered_component).to have_element(:svg, class: "octicon-#{icon}")
      expect(rendered_component).to have_element(:h3, text: heading)
      expect(rendered_component).to have_element(:p, text: description)
    end
  end

  shared_examples "renders a work packages table" do
    include_examples "renders the sprint report widget box"

    it "configures table to hide extra UI elements" do
      expect(table_element["data-configuration"]).to be_json_eql({
        "actionsColumnEnabled" => false,
        "columnMenuEnabled" => false,
        "contextMenuEnabled" => false,
        "inlineCreateEnabled" => false
      }.to_json)
    end

    it "renders a filtered work packages table" do
      expect(query_props).to match({
        "filters" => be_json_eql(expected_filters.to_json),
        "timestamps" => expected_timestamps,
        "sortBy" => [%w[position asc]].to_json,
        "columns[]" => %w[id subject type status assigned_to story_points],
        "showHierarchies" => false,
        "includeSubprojects" => false,
        **expected_extra_query_props
      }.compact)
    end
  end
end

RSpec.shared_examples "a pro sprint report widget" do
  context "without the baseline_comparison entitlement", with_ee: %i[sprint_report_pro_widgets] do
    it "renders nothing" do
      expect(rendered_html).to be_blank
    end
  end

  context "without the sprint_report_pro_widgets entitlement", with_ee: %i[baseline_comparison] do
    it "renders nothing" do
      expect(rendered_html).to be_blank
    end
  end

  context "without the view_sprints permission" do
    current_user { create(:user) }

    it "renders nothing" do
      expect(rendered_html).to be_blank
    end
  end

  context "with all permissions and entitlements" do
    it "renders the widget" do
      expect(rendered_component).to have_element(:h3, text: widget_name)
      expect(rendered_component).to have_css("opce-embedded-work-package-table")
    end
  end
end
