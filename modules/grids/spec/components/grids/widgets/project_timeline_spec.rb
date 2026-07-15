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
  let(:role) { create(:project_role, permissions: [:view_project_phases]) }
  let(:component) { described_class.new(project) }

  before { login_as(user) }

  describe "#render?" do
    context "with view_project_phases permission" do
      before { create(:member, user:, project:, roles: [role]) }

      it { expect(component.render?).to be(true) }
    end

    context "without permission" do
      it { expect(component.render?).to be(false) }
    end
  end

  describe "#any_phases?" do
    context "with no phases" do
      it { expect(component.any_phases?).to be(false) }
    end

    context "with an active phase" do
      before { create(:project_phase, project:) }

      it { expect(component.any_phases?).to be(true) }
    end

    context "with only an inactive phase" do
      before { create(:project_phase, :inactive, project:) }

      it { expect(component.any_phases?).to be(false) }
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

    context "with an additional inactive phase" do
      before { create(:project_phase, :inactive, project:) }

      it "excludes inactive phases" do
        expect(data.size).to eq(1)
      end
    end
  end

  describe "rendering" do
    before { create(:member, user:, project:, roles: [role]) }

    context "with no phases" do
      it "renders a blankslate" do
        render_inline(component)
        expect(page).to have_test_selector("project-timeline-widget-empty")
        expect(page).to have_no_css("opce-project-timeline-graph")
      end
    end

    context "with phases" do
      before { create(:project_phase, project:) }

      it "renders the Angular component with phases-data" do
        render_inline(component)
        expect(page).to have_css("opce-project-timeline-graph[phases-data]")
      end

      it "does not render a blankslate" do
        render_inline(component)
        expect(page).to have_no_test_selector("project-timeline-widget-empty")
      end
    end
  end
end
