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

RSpec.describe Projects::Settings::LifeCycle::IndexComponent, type: :component do
  let(:project) { create(:project) }

  subject(:rendered_component) do
    with_request_url("/projects/#{project.id}/settings/life_cycle") do
      render_inline(
        described_class.new(project:, life_cycle_definitions: Project::PhaseDefinition.order(position: :asc))
      )
    end
  end

  context "with definitions" do
    let!(:definition) { create(:project_phase_definition) }

    it_behaves_like "rendering Box", row_count: 1

    it "renders a row per definition" do
      expect(rendered_component).to have_css(".Box-row", text: definition.name)
    end

    it "renders the enable-all and disable-all header actions", :aggregate_failures do
      expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_enable_all"))
      expect(rendered_component).to have_link(accessible_name: I18n.t("projects.settings.actions.label_disable_all"))
    end
  end

  context "without definitions" do
    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("projects.settings.life_cycle.non_defined")
  end
end
