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
require_relative "shared_table_examples"

RSpec.describe Backlogs::SprintReports::Widgets::UnfinishedTable,
               type: :component,
               with_ee: %i[baseline_comparison sprint_report_pro_widgets] do
  include_context "with a sprint report work package table"

  let(:widget_name) { "Unfinished work packages" }
  let(:unfinished_count) { 4 }
  let(:breakdown_stubs) do
    {
      done_status_ids: [3, 4],
      unfinished: SprintWorkPackageBreakdown::Block.new(work_package_count: unfinished_count, story_points: 0)
    }
  end

  let(:expected_filters) do
    [
      { sprintId: { operator: "=", values: [sprint.id.to_s] } },
      { status: { operator: "!", values: %w[3 4] } }
    ]
  end

  it_behaves_like "a pro sprint report widget"

  context "when the sprint has no dates set" do
    let(:start_date) { nil }
    let(:finish_date) { nil }

    include_examples "renders a blankslate",
                     description: "Sprint start and finish dates are necessary to show unfinished work packages."
  end

  context "when the sprint has not started" do
    let(:started_at) { nil }

    include_examples "renders a blankslate",
                     description: "Unfinished work packages will appear here after the sprint starts."
  end

  context "when everything is finished" do
    let(:unfinished_count) { 0 }

    include_examples "renders a blankslate",
                     description: "All work packages in this sprint are completed.",
                     icon: :trophy,
                     heading: "Wow, all done!"
  end

  context "when the sprint is running" do
    let(:expected_timestamps) { nil }

    include_examples "renders a work packages table"
  end

  context "when the sprint is complete" do
    let(:completed_at) { 1.hour.ago }
    let(:expected_timestamps) { completed_at.iso8601 }

    include_examples "renders a work packages table"
  end
end
