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

RSpec.describe "Project phase definitions move", :skip_csrf, type: :rails_request, with_ee: %i[customize_life_cycle] do
  shared_let(:admin) { create(:admin) }
  shared_let(:definition_a) { create(:project_phase_definition) }
  shared_let(:definition_b) { create(:project_phase_definition) }

  current_user { admin }

  def move(definition, params)
    put move_admin_settings_project_phase_definition_path(definition),
        params:, headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  def ordered_ids
    Project::PhaseDefinition.order(:position).ids
  end

  it "moves the definition below the anchor" do
    move(definition_a, { list_type: "project_phase_definition", list_id: "", prev_id: definition_b.id.to_s })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq([definition_b.id, definition_a.id])
  end

  it "moves the definition to the top for a blank prev_id" do
    move(definition_b, { list_type: "project_phase_definition", list_id: "", prev_id: "" })
    expect(response).to have_http_status(:ok)
    expect(ordered_ids).to eq([definition_b.id, definition_a.id])
  end

  {
    "an unknown anchor" => -> { { list_type: "project_phase_definition", list_id: "", prev_id: "999999" } },
    "an omitted prev_id" => -> { { list_type: "project_phase_definition", list_id: "" } },
    "a wrong list_type" => -> { { list_type: "enumeration", list_id: "", prev_id: "" } },
    "a nonblank list_id" => -> { { list_type: "project_phase_definition", list_id: definition_b.id.to_s, prev_id: "" } },
    "a collection-valued prev_id" =>
      -> { { list_type: "project_phase_definition", list_id: "", prev_id: [definition_b.id.to_s] } },
    "an empty collection prev_id" => -> { { list_type: "project_phase_definition", list_id: "", prev_id: [""] } },
    "a collection-valued list_id" => -> { { list_type: "project_phase_definition", list_id: [""], prev_id: "" } }
  }.each do |description, params|
    it "422s without mutation for #{description}" do
      move(definition_a, instance_exec(&params))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(ordered_ids).to eq([definition_a.id, definition_b.id])
    end
  end

  it "renders the invalid-anchor error message on failure" do
    move(definition_a, { list_type: "project_phase_definition", list_id: "", prev_id: "999999" })
    expect(response.body).to include(I18n.t(:error_invalid_list_move_anchor))
  end

  it "updates the definitions list on success" do
    move(definition_a, { list_type: "project_phase_definition", list_id: "", prev_id: definition_b.id.to_s })
    expect(response.body)
      .to include('<turbo-stream action="update" target="settings-project-phase-definitions-index-component" method="morph">')
  end

  context "when not an admin" do
    current_user { create(:user) }

    it "is forbidden" do
      move(definition_a, { list_type: "project_phase_definition", list_id: "", prev_id: definition_b.id.to_s })
      expect(response).to have_http_status(:forbidden)
      expect(ordered_ids).to eq([definition_a.id, definition_b.id])
    end
  end

  context "without an enterprise token", with_ee: false do
    it "is unavailable" do
      move(definition_a, { list_type: "project_phase_definition", list_id: "", prev_id: definition_b.id.to_s })
      expect(response).to have_http_status(:payment_required)
      expect(ordered_ids).to eq([definition_a.id, definition_b.id])
    end
  end
end
