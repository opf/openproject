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

require "spec_helper"
require_relative "../base_create_service_shared_examples"

RSpec.describe Boards::SprintTaskBoardCreateService do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:status1) { create(:status) }
  shared_let(:status2) { create(:status) }
  shared_let(:project) { create(:project, types: [type_task]) }
  shared_let(:sprint) { create(:sprint, project:) }
  let(:user) { create(:admin) }
  let(:instance) { described_class.new(user:) }

  before do
    create(:workflow, type: type_task, old_status: status1, new_status: status2, role: create(:project_role))
  end

  subject { instance.call(project:, sprint:, name: "Sprint Task Board") }

  context "with all valid params" do
    it "is successful" do
      expect(subject).to be_success
    end

    it 'creates a "Status" action board', :aggregate_failures do
      board = subject.result

      expect(board.name).to eq("Sprint Task Board")
      expect(board.linked).to eq(sprint)
      expect(board.options[:type]).to eq("action")
      expect(board.options[:attribute]).to eq("status")
      expect(board.options[:highlightingMode]).to eq("priority")
      expect(board.options[:filters]).to eq(
        [{ sprint_id: { operator: "=", values: [sprint.id.to_s] } }]
      )
    end

    describe "widgets and queries" do
      let(:board) { subject.result }
      let(:widgets) { board.widgets }
      let(:queries) { Query.all }

      it "sets the status_id filter on each query and widget", :aggregate_failures do
        subject

        queries_filters = queries.flat_map(&:filters).map(&:to_hash)
        widgets_filters = widgets.flat_map { it.options["filters"] }

        expect(queries_filters).to match_array(widgets_filters)

        queries.each do |query|
          status_filter = query.filters.find { |f| f.field.to_s == "status_id" }
          expect(status_filter).not_to be_nil
          expect(status_filter.operator).to eq("=")
        end
      end

      it_behaves_like "sets the appropriate sort_criteria on each query"
    end
  end

  describe "status columns" do
    context "when a sprint board already exists on the project" do
      let(:status3) { create(:status) }
      let(:existing_sprint) { create(:sprint, project:) }

      let(:widget1) do
        build(:grid_widget,
              identifier: "work_package_query",
              start_row: 1, end_row: 2, start_column: 1, end_column: 2,
              options: {
                "queryId" => 1,
                "filters" => [{ "status_id" => { "operator" => "=", "values" => [status3.id.to_s] } }]
              })
      end

      let(:widget2) do
        build(:grid_widget,
              identifier: "work_package_query",
              start_row: 1, end_row: 2, start_column: 2, end_column: 3,
              options: {
                "queryId" => 2,
                "filters" => [{ "status_id" => { "operator" => "=", "values" => [status1.id.to_s] } }]
              })
      end

      before do
        create(:board_grid,
               project:,
               linked: existing_sprint,
               column_count: 2,
               options: { "type" => "action", "attribute" => "status" },
               widgets: [widget1, widget2])
      end

      it "reuses the columns from the most recently created sprint board" do
        board = subject.result
        query_names = board.contained_queries.pluck(:name)

        expect(query_names).to contain_exactly(status3.name, status1.name)
      end

      it "sets column_count to match the previous board's columns" do
        expect(subject.result.column_count).to eq(2)
      end
    end

    context "when no sprint board exists on the project" do
      context "when the sprint has work packages with different types" do
        let(:other_type) { create(:type) }
        let(:status3) { create(:status) }

        before do
          create(:workflow, type: other_type, old_status: status1, new_status: status3, role: create(:project_role))
          create(:work_package, project:, sprint:, type: other_type, status: status1)
        end

        it "uses the union of statuses from all work package types" do
          board = subject.result
          query_names = board.contained_queries.pluck(:name)

          expect(query_names).to contain_exactly(status1.name, status3.name)
        end

        it "sets column_count to match the number of statuses" do
          type_ids = sprint.work_packages.distinct.pluck(:type_id)
          expected_count = Type.statuses(type_ids).count

          expect(subject.result.column_count).to eq(expected_count)
        end
      end

      context "when the sprint has no work packages" do
        it "falls back to the project type statuses" do
          board = subject.result
          query_names = board.contained_queries.pluck(:name)

          expect(query_names).to contain_exactly(status1.name, status2.name)
        end

        it "sets column_count to match the number of project type statuses" do
          expect(subject.result.column_count).to eq(2)
        end
      end
    end
  end
end
