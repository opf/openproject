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

RSpec.describe Settings::ProjectPhaseDefinitions::IndexComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject(:rendered_component) { render_inline(described_class.new(definitions:)) }

  # The row component reads the +project_count+ column added by the
  # +with_project_count+ scope, so definitions are loaded through it.
  let(:definitions) { Project::PhaseDefinition.with_project_count }

  def drop_url_for(definition)
    drop_admin_settings_project_phase_definition_path(definition)
  end

  context "with definitions" do
    let!(:draggable_records) { create_list(:project_phase_definition, 2) }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "a reorderable Border Box List", drag_type: "life-cycle-step-definition"
  end

  context "without definitions" do
    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("settings.project_phase_definitions.non_defined")
  end
end
