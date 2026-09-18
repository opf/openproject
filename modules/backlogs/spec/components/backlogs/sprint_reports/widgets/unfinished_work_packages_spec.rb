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
require_relative "shared_work_package_table_examples"

RSpec.describe Backlogs::SprintReports::Widgets::UnfinishedTable, type: :component do
  include_examples "sprint report work package table widget" do
    let(:widget_name) { "Unfinished work packages" }
    let(:unfinished_count) { 4 }
    let(:breakdown_overrides) do
      {
        done_status_ids: [3, 4],
        unfinished: SprintWorkPackageBreakdown::Block.new(work_package_count: unfinished_count, story_points: 0)
      }
    end
  end

  context "with all permissions and entitlements", with_ee: %i[baseline_comparison sprint_report_pro_widgets] do
    context "when the sprint has no dates set" do
      let(:start_date) { nil }
      let(:finish_date) { nil }

      include_examples "renders a blankslate" do
        let(:description) { "A sprint start and finish dates are necessary to show unfinished work packages." }
      end
    end

    context "when the sprint has not started" do
      let(:started_at) { nil }

      include_examples "renders a blankslate" do
        let(:description) { "Unfinished work packages will appear here after the sprint starts." }
      end
    end

    context "when everything is finished" do
      let(:unfinished_count) { 0 }

      include_examples "renders a blankslate" do
        let(:icon) { :trophy }
        let(:heading) { "Wow, all done!" }
        let(:description) { "All work packages in this sprint are completed." }
      end
    end

    context "when the sprint is running" do
      it "renders a filtered table" do
        expect(query_props["filters"]).to be_json_eql([
          { sprintId: { operator: "=", values: [sprint.id.to_s] } },
          { status: { operator: "!", values: %w[3 4] } }
        ].to_json)
      end

      it "renders a non baseline table" do
        expect(query_props).not_to have_key("timestamps")
      end

      it "sorts by position" do
        expect(query_props["sortBy"]).to eq([%w[position asc]].to_json)
      end

      it "renders specific columns" do
        expect(query_props["columns[]"]).to eq(%w[id subject type status assigned_to])
      end

      it "renders a flat table so that ancestors outside the filters stay out" do
        expect(query_props["showHierarchies"]).to be(false)
      end
    end

    context "when the sprint is complete" do
      let(:completed_at) { 1.hour.ago }

      it "renders a filtered table" do
        expect(query_props["filters"]).to be_json_eql([
          { sprintId: { operator: "=", values: [sprint.id.to_s] } },
          { status: { operator: "!", values: %w[3 4] } }
        ].to_json)
      end

      it "renders a baseline table using completion timestamp" do
        expect(query_props["timestamps"]).to eq(completed_at.iso8601)
      end

      it "sorts by position" do
        expect(query_props["sortBy"]).to eq([%w[position asc]].to_json)
      end

      it "renders specific columns" do
        expect(query_props["columns[]"]).to eq(%w[id subject type status assigned_to])
      end

      it "renders a flat table so that ancestors outside the filters stay out" do
        expect(query_props["showHierarchies"]).to be(false)
      end
    end
  end
end
