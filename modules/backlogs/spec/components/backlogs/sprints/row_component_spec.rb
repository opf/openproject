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

RSpec.describe Backlogs::Sprints::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:columns) { %i[name status start_date finish_date work_package_count] }
  let(:work_package_counts) { {} }
  let(:table) do
    instance_double(
      Backlogs::Sprints::TableComponent,
      columns:,
      grid_class: "test",
      has_actions?: false,
      mobile_columns: %i[name status],
      mobile_labels: [],
      project:,
      work_package_counts:
    )
  end

  subject(:rendered_component) do
    render_inline(described_class.new(row: sprint, table:))
  end

  before do
    login_as(user)
    allow(table).to receive(:main_column?).and_return(false)
  end

  describe "name link" do
    context "when sprint is in planning" do
      let(:sprint) { build_stubbed(:sprint, project:, status: :in_planning, name: "Planning sprint") }

      it "links to the backlog" do
        expect(rendered_component).to have_link("Planning sprint", href: project_backlogs_backlog_path(project))
      end
    end

    context "when sprint is active" do
      let(:sprint) { build_stubbed(:sprint, project:, status: :active, name: "Active sprint") }

      context "and a board exists" do
        let(:board) { build_stubbed(:board_grid, project:, linked: sprint) }

        before do
          allow(sprint).to receive(:task_board_for).with(project).and_return(board)
        end

        it "links to the sprint task board" do
          expect(rendered_component).to have_link("Active sprint", href: project_work_package_board_path(project, board))
        end
      end

      context "and the board is missing" do
        before do
          allow(sprint).to receive(:task_board_for).with(project).and_return(nil)
        end

        it "renders the sprint name as text instead of a link" do
          expect(rendered_component).to have_no_link("Active sprint")
        end
      end
    end

    context "when sprint is completed", with_settings: { work_package_list_default_columns: %i[id subject] } do
      let(:sprint) { build_stubbed(:sprint, project:, status: :completed, name: "Completed sprint", id: 123) }

      it "links to work packages filtered by sprint" do
        query_props = {
          f: [{ n: "sprintId", o: "=", v: ["123"] }],
          t: "position:asc",
          c: %w[id subject sprint]
        }.to_json

        expect(rendered_component).to have_link(
          "Completed sprint",
          href: project_work_packages_path(project, query_props:)
        )
      end
    end
  end

  describe "additional row behavior" do
    let(:sprint) do
      build_stubbed(:sprint,
                    project:,
                    status: :in_planning,
                    name: "Sprint 42",
                    start_date: Date.new(2025, 9, 1),
                    finish_date: Date.new(2025, 9, 15))
    end

    context "with a mapped work package count" do
      let(:work_package_counts) { { sprint.id => 7 } }

      it "shows dates, status and mapped work package count" do
        expect(rendered_component).to have_css(".start_date", text: "09/01/2025")
        expect(rendered_component).to have_css(".finish_date", text: "09/15/2025")
        expect(rendered_component).to have_css(".status", text: I18n.t(:"activerecord.attributes.sprint.statuses.in_planning"))
        expect(rendered_component).to have_css(".work_package_count", text: "7")
      end
    end

    context "without a mapped work package count" do
      let(:work_package_counts) { {} }

      it "falls back to zero" do
        expect(rendered_component).to have_css(".work_package_count", text: "0")
      end
    end
  end
end
