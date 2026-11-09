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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe Settings::ProjectPhaseDefinitions::IndexComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) do
    with_request_url(admin_settings_project_phase_definitions_path) do
      render_inline(described_class.new(definitions:))
    end
  end

  # The row component reads the +project_count+ column added by the
  # +with_project_count+ scope, so definitions are loaded through it.
  let(:definitions) { Project::PhaseDefinition.with_project_count }

  context "with definitions", with_ee: %i[customize_life_cycle] do
    let!(:sortable_records) { create_list(:project_phase_definition, 2) }

    it_behaves_like "rendering Box", row_count: 2

    # The component combines the sortable-lists controller with the
    # border-box-filter controller on the same wrapper, so the generic
    # "a sortable-lists root" shared example (which expects a single
    # controller) does not apply here.
    it "wires #settings-project-phase-definitions-index-component as the sortable-lists root" do
      expect(rendered_component).to have_css("#settings-project-phase-definitions-index-component") do |root|
        expect(root["data-controller"]).to eq("projects--settings--border-box-filter sortable-lists")
        expect(root["data-sortable-lists-move-url-template-value"])
          .to eq("/admin/settings/project_phase_definitions/{id}/move")
        expect(root["data-sortable-lists-sortable-lists--list-outlet"])
          .to eq("#settings-project-phase-definitions-index-component [data-controller~='sortable-lists--list']")
        expect(root["data-sortable-lists-sortable-lists--item-outlet"])
          .to eq("#settings-project-phase-definitions-index-component [data-controller~='sortable-lists--item']")
      end
    end

    it_behaves_like "a sortable-lists list",
                    list_type: "project_phase_definition",
                    name: I18n.t("settings.project_phase_definitions.section_header")
    it_behaves_like "a Border Box sortable list", row_count: 2
    it_behaves_like "sortable-lists items", list_type: "project_phase_definition"
    it_behaves_like "no legacy drag-and-drop wiring"
  end

  context "without definitions" do
    let(:definitions) { Project::PhaseDefinition.with_project_count.where(id: nil) }

    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("settings.project_phase_definitions.non_defined")
  end

  context "without enterprise token" do
    let!(:sortable_records) { create_list(:project_phase_definition, 2) }

    it "renders no sortable-lists wiring" do
      expect(rendered_component).to have_no_css("[data-controller*='sortable-lists']")
    end
  end
end
