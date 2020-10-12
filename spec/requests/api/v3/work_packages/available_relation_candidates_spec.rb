#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe ::API::V3::Relations::RelationRepresenter, type: :request do
  let(:user) { FactoryBot.create :admin }

  let(:project_1) { FactoryBot.create :project }

  let!(:wp_1) { FactoryBot.create :work_package, project: project_1, subject: "WP 1" }

  let!(:wp_1_1) do
    FactoryBot.create :work_package, parent: wp_1, project: project_1, subject: "WP 1.1"
  end

  let!(:wp_1_2) do
    FactoryBot.create :work_package, parent: wp_1, project: project_1, subject: "WP 1.2"
  end

  let!(:wp_1_2_1) do
    FactoryBot.create :work_package, parent: wp_1_2, project: project_1, subject: "WP 1.2.1"
  end

  let(:project_2) { FactoryBot.create :project }

  let!(:wp_2) { FactoryBot.create :work_package, project: project_2, subject: "WP 2" }
  let!(:wp_2_1) { FactoryBot.create :work_package, project: project_2, subject: "WP 2.1" }
  let!(:wp_2_2) { FactoryBot.create :work_package, project: project_2, subject: "WP 2.2" }

  let!(:relation_wp_2_1_to_wp_2_2) do
    FactoryBot.create :relation, from: wp_2_1, to: wp_2_2, relation_type: "relates"
  end

  let(:href) { "/api/v3/work_packages/#{wp_1.id}/available_relation_candidates?query=WP" }
  let(:request) { get href }
  let(:result) do
    request
    JSON.parse last_response.body
  end
  let(:subjects) { work_packages.map { |e| e["subject"] } }

  def work_packages
    result["_embedded"]["elements"]
  end

  before do
    login_as user
  end

  context 'with no permissions' do
    let(:user) { FactoryBot.create(:user) }

    it 'does not return any work packages' do
      expect(result["errorIdentifier"]).to eq('urn:openproject-org:api:v3:errors:NotFound')
    end
  end

  context "without cross project relations",
          with_settings: { cross_project_work_package_relations: false } do

    describe "relation candidates for wp_1 (in hierarchy)" do
      it "should return an empty list" do # as relations to ancestors or descendents is not allowed
        expect(result["count"]).to eq 0
      end
    end

    describe "relation candidates for wp_2" do
      let(:href) { "/api/v3/work_packages/#{wp_2.id}/available_relation_candidates?query=WP" }

      it "should return WP 2.1 and 2.2" do
        expect(subjects).to match_array ["WP 2.1", "WP 2.2"]
      end
    end

    describe "case-insensitive matches" do
      let(:href) { "/api/v3/work_packages/#{wp_2.id}/available_relation_candidates?query=wp" }

      it "should return WP 2.1 and 2.2" do
        expect(subjects).to match_array ["WP 2.1", "WP 2.2"]
      end
    end

    describe "relation candidates for WP 2.2 (circular dependency check)" do
      let(:href) { "/api/v3/work_packages/#{wp_2_2.id}/available_relation_candidates?query=WP" }

      it "should return just WP 2, not WP 2.1" do
        expect(subjects).to match_array ["WP 2"]
      end
    end
  end

  context "with cross project relations",
          with_settings: { cross_project_work_package_relations: true } do

    describe "relation candidates for wp_1 (in hierarchy)" do
      let(:href) { "/api/v3/work_packages/#{wp_1.id}/available_relation_candidates?query=WP" }

      it "should return WP 2 and all WP 2.x" do
        expect(subjects).to match_array ["WP 2", "WP 2.1", "WP 2.2"]
      end
    end

    describe "relation candidates for wp_2" do
      let(:href) { "/api/v3/work_packages/#{wp_2.id}/available_relation_candidates?query=WP&type=follows" }

      it "should return WP 2.1 and 2.2, WP 1 and all WP 1.x" do
        expect(subjects).to match_array ["WP 1", "WP 1.1", "WP 1.2", "WP 1.2.1", "WP 2.1", "WP 2.2"]
      end

      describe 'with an already existing relationship from the work package' do
        let!(:relation_wp_2_to_wp_2_2) do
          FactoryBot.create :relation, from: wp_2, to: wp_2_2, relation_type: "relates"
        end

        let!(:relation_wp_1_1_to_wp_2) do
          FactoryBot.create :relation, from: wp_1_1, to: wp_2, relation_type: "relates"
        end

        context 'for a follows relationship' do
          it 'does not contain the work packages with which a relationship already exists' do
            expect(subjects).to match_array ["WP 1.2", "WP 1.2.1", "WP 2.1"]
          end
        end

        context 'for a relates relationship' do
          let(:href) { "/api/v3/work_packages/#{wp_2.id}/available_relation_candidates?query=WP&type=relates" }

          it 'does not contain the work packages with which a relationship already exists but the parent' do
            expect(subjects).to match_array ["WP 1", "WP 1.2", "WP 1.2.1", "WP 2.1"]
          end
        end
      end
    end

    context 'when a project is archived' do
      let(:project_1) { FactoryBot.create :project, active: false }
      let(:href) { "/api/v3/work_packages/#{wp_2.id}/available_relation_candidates?query=WP" }

      it 'does not return work packages from that project' do
        expect(subjects).to match_array ["WP 2.1", "WP 2.2"]
      end
    end
  end
end
