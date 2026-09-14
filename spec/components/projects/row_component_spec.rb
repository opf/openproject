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
#
require "rails_helper"

RSpec.describe Projects::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project, name: "My Project No. 1", identifier: "myproject_no_1") }
  let(:columns) { [Queries::Projects::Selects::Default.new(:name)] }
  let(:table) do
    instance_double(Projects::TableComponent,
                    columns:,
                    favorited_project_ids: [],
                    project_phase_by_definition: nil)
  end

  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_component(row: [project, 0], table:)
  end

  describe "Project Name" do
    it "renders the project name as a link" do
      expect(rendered_component).to have_css(
        "a[data-turbo='false'][href='/projects/myproject_no_1']",
        text: "My Project No. 1"
      )
    end
  end

  describe "Menu" do
    context "when the user is anonymous" do
      let(:user) { build_stubbed(:anonymous) }

      it "renders no action menu" do
        expect(rendered_component).not_to have_element "action-menu"
      end
    end

    context "when the user is logged in" do
      it "renders an async Primer ActionMenu shell" do
        expect(rendered_component).to have_element "action-menu"
      end
    end
  end

  describe "project phase columns" do
    let(:project) { create(:project) }
    let(:definition) { create(:project_phase_definition) }
    let(:phase) do
      create(:project_phase,
             project:,
             definition:,
             start_date: Date.new(2024, 12, 1),
             finish_date: Date.new(2024, 12, 13))
    end
    let(:columns) { [Queries::Projects::Selects::ProjectPhase.new(:"project_phase_#{definition.id}")] }

    before do
      allow(table).to receive(:project_phase_by_definition).with(definition, project).and_return(phase)
    end

    context "with permission to view project phases" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_project_phases] }) }

      it "renders the phase dates" do
        expect(rendered_component).to have_css(
          ".project_phase_#{definition.id}",
          text: /12\/01\/2024.*12\/13\/2024/m
        )
      end

      context "without an active phase for the project" do
        let(:phase) { nil }

        it "leaves the phase cell empty" do
          expect(rendered_component).to have_css(".project_phase_#{definition.id}", text: "")
          expect(rendered_component).to have_no_text("12/01/2024")
        end
      end
    end

    context "without permission to view project phases" do
      let(:user) { create(:user) }

      it "leaves the phase cell empty" do
        expect(rendered_component).to have_css(".project_phase_#{definition.id}", text: "")
        expect(rendered_component).to have_no_text("12/01/2024")
      end
    end
  end

  describe "custom comment columns" do
    let(:project) { create(:project) }
    let(:custom_field) do
      create(:string_project_custom_field, :has_comment, projects: [project])
    end
    let(:columns) { [Queries::Projects::Selects::CustomComment.new(:"cfc_#{custom_field.id}")] }

    before do
      create(:custom_comment, customized: project, custom_field:, text: "Visible project comment")
    end

    context "with permission to view project attributes" do
      let(:user) { create(:user, member_with_permissions: { project => %i[view_project_attributes] }) }

      it "renders the custom comment" do
        expect(rendered_component).to have_css(
          ".cfc_#{custom_field.id}",
          text: "Visible project comment"
        )
      end
    end

    context "without permission to view project attributes" do
      let(:user) { create(:user) }

      it "leaves the custom comment cell empty" do
        expect(rendered_component).to have_css(".cfc_#{custom_field.id}", text: "")
        expect(rendered_component).to have_no_text("Visible project comment")
      end
    end
  end
end
