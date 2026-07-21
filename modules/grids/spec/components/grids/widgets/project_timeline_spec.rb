# frozen_string_literal: true

# -- copyright
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
# ++

require "rails_helper"

RSpec.describe Grids::Widgets::ProjectTimeline, type: :component do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:phases_role) { create(:project_role, permissions: [:view_project_phases]) }
  let(:wp_role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:component) { described_class.new(project) }

  before { login_as(user) }

  describe "#render?" do
    context "with view_project_phases permission" do
      before { create(:member, user:, project:, roles: [phases_role]) }

      it { expect(component.render?).to be(true) }
    end

    context "with view_work_packages permission" do
      before { create(:member, user:, project:, roles: [wp_role]) }

      it { expect(component.render?).to be(true) }
    end

    context "without either permission" do
      it { expect(component.render?).to be(false) }
    end
  end

  describe "#any_content?" do
    context "with no phases and no milestones" do
      it { expect(component.any_content?).to be(false) }
    end

    context "with an active phase" do
      before { create(:project_phase, project:) }

      it { expect(component.any_content?).to be(true) }
    end

    context "with only an inactive phase" do
      before { create(:project_phase, :inactive, project:) }

      it { expect(component.any_content?).to be(false) }
    end

    context "with a visible milestone work package" do
      let(:milestone_type) { create(:type, is_milestone: true) }

      before do
        create(:member, user:, project:, roles: [wp_role])
        create(:work_package, project:, type: milestone_type, due_date: Time.zone.today)
      end

      it { expect(component.any_content?).to be(true) }
    end
  end

  describe "#phases_data" do
    let(:definition) { create(:project_phase_definition, :with_start_gate, :with_finish_gate) }
    let!(:phase) { create(:project_phase, project:, definition:) }

    subject(:data) { JSON.parse(component.phases_data) }

    it "includes all required fields" do
      expect(data.first).to include(
        "id" => phase.id,
        "definitionId" => definition.id,
        "name" => definition.name,
        "startDate" => phase.start_date.iso8601,
        "endDate" => phase.finish_date.iso8601,
        "startGate" => true,
        "startGateName" => definition.start_gate_name,
        "finishGate" => true,
        "finishGateName" => definition.finish_gate_name
      )
    end

    context "when the phase has only a start_date but no finish_date" do
      let!(:phase) { create(:project_phase, project:, definition:, finish_date: nil) }

      it "does not include start or finish gates" do
        expect(data.first).to include("startGate" => false, "finishGate" => false)
      end
    end

    context "with an additional inactive phase" do
      before { create(:project_phase, :inactive, project:) }

      it "excludes inactive phases" do
        expect(data.size).to eq(1)
      end
    end
  end

  describe "#milestones_data" do
    let(:milestone_type) { create(:type, is_milestone: true) }
    let!(:milestone) { create(:work_package, project:, type: milestone_type, due_date: Time.zone.today) }

    subject(:data) { JSON.parse(component.milestones_data) }

    before { create(:member, user:, project:, roles: [wp_role]) }

    it "includes all required fields" do
      expect(data.first).to include(
        "id" => milestone.id,
        "subject" => milestone.subject,
        "date" => milestone.due_date.iso8601,
        "typeId" => milestone_type.id
      )
    end

    it "excludes work packages without a due date" do
      create(:work_package, project:, type: milestone_type, due_date: nil)
      expect(data.size).to eq(1)
    end

    it "excludes non-milestone work packages" do
      create(:work_package, project:, due_date: Time.zone.today)
      expect(data.size).to eq(1)
    end

    it "orders by due date" do
      earlier = create(:work_package, project:, type: milestone_type, due_date: Time.zone.today - 1)
      expect(data.pluck("id")).to eq([earlier.id, milestone.id])
    end
  end

  describe "#gantt_link" do
    let(:milestone_type) { create(:type, is_milestone: true) }

    context "when no milestone types are enabled in the project" do
      it { expect(component.gantt_link).to be_nil }
    end

    context "when milestone types are enabled in the project" do
      before do
        project.types << milestone_type
        render_inline(component)
      end

      subject(:query_props) { JSON.parse(CGI.parse(URI.parse(component.gantt_link).query)["query_props"].first) }

      it "includes the milestone type filter" do
        expect(query_props["f"]).to include(include("n" => "type", "o" => "=", "v" => [milestone_type.id.to_s]))
      end

      it "sets hi to false" do
        expect(query_props["hi"]).to be(false)
      end

      it "enables the timeline view" do
        expect(query_props["tv"]).to be(true)
      end
    end
  end

  describe "rendering" do
    before { create(:member, user:, project:, roles: [phases_role, wp_role]) }

    context "with no content" do
      it "renders a blankslate" do
        render_inline(component)
        expect(page).to have_test_selector("project-timeline-widget-empty")
        expect(page).to have_no_css("opce-project-timeline-graph")
      end
    end

    context "with phases" do
      before { create(:project_phase, project:) }

      it "renders the Angular component with phases-data and milestones-data" do
        render_inline(component)
        expect(page).to have_css("opce-project-timeline-graph[phases-data][milestones-data]")
      end

      it "does not render a blankslate" do
        render_inline(component)
        expect(page).to have_no_test_selector("project-timeline-widget-empty")
      end
    end

    context "with only a milestone" do
      let(:milestone_type) { create(:type, is_milestone: true) }

      before { create(:work_package, project:, type: milestone_type, due_date: Time.zone.today) }

      it "renders the Angular component" do
        render_inline(component)
        expect(page).to have_css("opce-project-timeline-graph")
      end
    end

    context "without view_work_packages permission" do
      before { Member.find_by(user_id: user.id, project_id: project.id).update!(roles: [phases_role]) }

      it "does not render the gantt footer link" do
        render_inline(component)
        expect(page).to have_no_link(I18n.t("grids.widgets.project_timeline.gantt_link"))
      end
    end
  end
end
