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

RSpec.describe API::V3::Sprints::SprintRepresenter, "rendering" do
  include API::V3::Utilities::PathHelper

  let(:workspace) { build_stubbed(:project) }
  let(:start_date) { Date.new(2024, 1, 1) }
  let(:finish_date) { Date.new(2024, 1, 10) }
  let(:status) { "in_planning" }
  let(:sprint) do
    build_stubbed(:sprint,
                  project: workspace,
                  status:,
                  name: "Sprint 1",
                  start_date:,
                  finish_date:)
  end
  let(:current_user) { build_stubbed(:user) }
  let(:embed_links) { true }
  let(:representer) { described_class.create(sprint, current_user:, embed_links:) }

  subject(:generated) { representer.to_json }

  it { is_expected.to include_json("Sprint".to_json).at_path("_type") }

  it "fulfills the documented schema" do
    expect(generated).to match_json_schema.from_docs("sprint_model")
  end

  describe "links" do
    it { is_expected.to have_json_type(Object).at_path("_links") }

    describe "self" do
      it_behaves_like "has a titled link" do
        let(:link) { "self" }
        let(:href) { api_v3_paths.sprint(sprint.id) }
        let(:title) { sprint.name }
      end
    end

    describe "definingWorkspace" do
      it_behaves_like "has workspace linked" do
        let(:link) { "definingWorkspace" }
      end
    end

    describe "status" do
      let(:link) { "status" }

      context "with in_planning value" do
        it_behaves_like "has a titled link" do
          let(:href) { "urn:openproject-org:api:v3:sprints:status:in_planning" }
          let(:title) { I18n.t("activerecord.attributes.sprint.statuses.in_planning") }
        end
      end

      context "with active value" do
        let(:status) { "active" }

        it_behaves_like "has a titled link" do
          let(:href) { "urn:openproject-org:api:v3:sprints:status:active" }
          let(:title) { I18n.t("activerecord.attributes.sprint.statuses.active") }
        end
      end

      context "with completed value" do
        let(:status) { "completed" }

        it_behaves_like "has a titled link" do
          let(:href) { "urn:openproject-org:api:v3:sprints:status:completed" }
          let(:title) { I18n.t("activerecord.attributes.sprint.statuses.completed") }
        end
      end
    end
  end

  describe "properties" do
    describe "_type" do
      it_behaves_like "property", :_type do
        let(:value) { "Sprint" }
      end
    end

    describe "id" do
      it_behaves_like "property", :id do
        let(:value) { sprint.id }
      end
    end

    describe "name" do
      it_behaves_like "property", :name do
        let(:value) { sprint.name }
      end
    end

    describe "startDate" do
      it_behaves_like "has ISO 8601 date only" do
        let(:date) { start_date }
        let(:json_path) { "startDate" }
      end
    end

    describe "finishDate" do
      it_behaves_like "has ISO 8601 date only" do
        let(:date) { finish_date }
        let(:json_path) { "finishDate" }
      end
    end

    describe "createdAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { sprint.created_at }
        let(:json_path) { "createdAt" }
      end
    end

    describe "updatedAt" do
      it_behaves_like "has UTC ISO 8601 date and time" do
        let(:date) { sprint.updated_at }
        let(:json_path) { "updatedAt" }
      end
    end
  end

  describe "embedded" do
    it_behaves_like "has workspace embedded" do
      let(:embedded_path) { "_embedded/definingWorkspace" }
    end
  end
end
