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

RSpec.describe Backlogs::SprintReports::Widgets::AddedTable,
               type: :component,
               with_ee: %i[baseline_comparison sprint_report_pro_widgets] do
  include_context "with a sprint report work package table"

  shared_let(:work_packages) { create_list(:work_package, 2, project:) }

  let(:widget_name) { "Sprint scope increase" }
  let(:added_after_start_ids) { work_packages.map(&:id) }
  let(:breakdown_stubs) do
    { added_after_start_ids: }
  end

  let(:expected_filter_ids) { work_packages.map { it.id.to_s } }
  let(:expected_filters) do
    [
      { project: { operator: "=", values: [project.id.to_s] } },
      { sprintId: { operator: "=", values: [sprint.id.to_s] } },
      { id: { operator: "=", values: expected_filter_ids } }
    ]
  end

  it_behaves_like "a pro sprint report widget"

  context "when the sprint has no dates set" do
    let(:start_date) { nil }
    let(:finish_date) { nil }

    include_examples "renders a blankslate",
                     description: "Sprint start and finish dates are necessary to show added work packages."
  end

  context "when the sprint has not started" do
    let(:started_at) { nil }

    include_examples "renders a blankslate",
                     description: "Added work packages will appear here after the sprint starts."
  end

  context "when nothing was added" do
    let(:added_after_start_ids) { [] }

    include_examples "renders a blankslate",
                     description: "Work packages that were added after the sprint start date will appear here."
  end

  context "when the sprint is running" do
    let(:expected_timestamps) { "#{started_at.iso8601},PT0S" }

    include_examples "renders a work packages table"
  end

  context "when the sprint is complete" do
    let(:completed_at) { 1.hour.ago }
    let(:expected_timestamps) { "#{started_at.iso8601},#{completed_at.iso8601}" }

    include_examples "renders a work packages table"
  end

  context "with work packages that moved from the project" do
    let(:expected_timestamps) { "#{started_at.iso8601},PT0S" }

    context "to a subproject that user may see" do
      shared_let(:in_visible_subproject) do
        create(
          :work_package,
          project: create(:project, parent: project, member_with_permissions: { user => %i[view_work_packages] })
        )
      end
      let(:added_after_start_ids) { super() + [in_visible_subproject.id] }

      let(:expected_filter_ids) { super() + [in_visible_subproject.id.to_s] }

      include_examples "renders a work packages table"
    end

    context "to a subproject that user may not see" do
      shared_let(:in_invisible_subproject) do
        create(:work_package, project: create(:project, parent: project))
      end
      let(:added_after_start_ids) { super() + [in_invisible_subproject.id] }

      include_examples "renders a work packages table"
    end

    context "to an unrelated project that user may see" do
      shared_let(:in_visible_other_project) do
        create(
          :work_package,
          project: create(:project, member_with_permissions: { user => %i[view_work_packages] })
        )
      end
      let(:added_after_start_ids) { super() + [in_visible_other_project.id] }

      let(:expected_filter_ids) { super() + [in_visible_other_project.id.to_s] }

      include_examples "renders a work packages table"
    end

    context "to an unrelated project that user may not see" do
      shared_let(:in_invisible_other_project) do
        create(:work_package)
      end
      let(:added_after_start_ids) { super() + [in_invisible_other_project.id] }

      include_examples "renders a work packages table"
    end
  end

  context "when no work package is available in the project by historical ids" do
    let(:added_after_start_ids) { super().map { it + 1000 } }

    include_examples "renders a blankslate",
                     description: "Work packages that were added after the sprint start date will appear here."
  end
end
