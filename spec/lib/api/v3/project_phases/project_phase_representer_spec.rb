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

require "spec_helper"

RSpec.describe API::V3::ProjectPhases::ProjectPhaseRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:definition) { build_stubbed(:project_phase_definition, :with_gates) }
  let(:project) { build_stubbed(:project) }
  let(:phase) { build_stubbed(:project_phase, definition:, project:) }
  let(:representer) do
    described_class.create(phase, current_user:, embed_links: true)
  end

  subject { representer.to_json }

  describe "_links" do
    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.project_phase phase.id }
        let(:title) { phase.name }
      end
    end

    describe "definition" do
      it_behaves_like "has a titled link" do
        let(:link) { "definition" }
        let(:href) { api_v3_paths.project_phase_definition definition.id }
        let(:title) { definition.name }
      end
    end

    describe "project" do
      it_behaves_like "has a titled link" do
        let(:link) { "project" }
        let(:href) { api_v3_paths.project project.id }
        let(:title) { project.name }
      end
    end
  end

  describe "properties" do
    it_behaves_like "property", :_type do
      let(:value) { "ProjectPhase" }
    end

    it_behaves_like "property", :id do
      let(:value) { phase.id }
    end

    it_behaves_like "property", :name do
      let(:value) { phase.name }
    end

    it_behaves_like "property", :active do
      let(:value) { phase.active }
    end

    describe "createdAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { phase.created_at }
        let(:json_path) { "createdAt" }
      end
    end

    describe "updatedAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { phase.updated_at }
        let(:json_path) { "updatedAt" }
      end
    end
  end
end
