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

require "spec_helper"

RSpec.describe API::V3::WorkPackages::WorkPackagePayloadRepresenter, "parsing" do
  include API::V3::Utilities::PathHelper

  let(:member) { build_stubbed(:user) }
  let(:hash) { {} }
  let(:current_user) { member }
  let(:representer) do
    described_class.create(API::V3::WorkPackages::ParseParamsService::ParsingStruct.new, current_user:)
  end
  let(:duration) { nil }

  subject { representer.from_hash(hash.stringify_keys) }

  describe "duration" do
    let(:hash) do
      {
        duration: "P6D"
      }
    end

    it "parses from iso8601 format" do
      expect(subject.duration).to eq(6)
    end
  end

  describe "project_phase" do
    let(:project) { build_stubbed(:project_with_types, phases: project_phase.present? ? [project_phase] : []) }
    let(:project_phase) { build_stubbed(:project_phase, definition: project_phase_definition) }
    let(:project_phase_definition) { build_stubbed(:project_phase_definition) }

    let(:hash) do
      {
        _links: {
          "projectPhase" => {
            "href" => api_v3_paths.project_phase(project_phase.id)
          },
          "project" => {
            "href" => api_v3_paths.project(project.id)
          }
        }
      }
    end

    before do
      phase_scope = instance_double(ActiveRecord::Relation)
      allow(Project::Phase)
        .to receive(:where)
              .with(id: project_phase.id.to_s)
              .and_return(phase_scope)

      allow(phase_scope)
        .to receive(:pick)
            .with(:definition_id)
            .and_return(project_phase_definition.id)
    end

    it "parses to the project_phase_definition_id" do
      expect(subject.project_phase_definition_id).to eq(project_phase_definition.id.to_s)
    end
  end
end
