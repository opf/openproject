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

RSpec.describe API::V3::WorkPackages::AvailableRelationCandidatesAPI do
  shared_let(:user) { create(:admin) }

  shared_let(:project1) { create(:project) }

  shared_let(:wp1) { create(:work_package, project: project1, subject: "WP 1") }

  shared_let(:wp1_1) do
    create(:work_package, parent: wp1, project: project1, subject: "WP 1.1")
  end

  shared_let(:wp1_2) do
    create(:work_package, parent: wp1, project: project1, subject: "WP 1.2")
  end

  shared_let(:wp1_2_1) do
    create(:work_package, parent: wp1_2, project: project1, subject: "WP 1.2.1")
  end

  shared_let(:project2) { create(:project) }

  shared_let(:wp2) { create(:work_package, project: project2, subject: "WP 2") }
  shared_let(:wp2_1) { create(:work_package, project: project2, subject: "WP 2.1") }
  shared_let(:wp2_2) { create(:work_package, project: project2, subject: "WP 2.2") }

  shared_let(:relation_wp2_1_to_wp2_2) do
    create(:relation, from: wp2_1, to: wp2_2, relation_type: "relates")
  end
  let(:href) { "/api/v3/work_packages/#{wp1.id}/available_relation_candidates?query=WP" }
  let(:request) { get href }
  let(:result) do
    request
    JSON.parse last_response.body
  end
  let(:subjects) { work_packages.pluck("id") }

  def work_packages
    result["_embedded"]["elements"]
  end

  current_user { user }

  context "with no permissions" do
    let(:user) { create(:user) }

    it "does not return any work packages" do
      expect(result["errorIdentifier"]).to eq("urn:openproject-org:api:v3:errors:NotFound")
    end
  end

  context "without cross project relations",
          with_settings: { cross_project_work_package_relations: false } do
    describe "relation candidates for wp1 (in hierarchy)" do
      it "returns WP 1.2.1" do
        expect(subjects).to contain_exactly(wp1_2_1.id)
      end
    end

    describe "relation candidates for wp2" do
      let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP" }

      it "returns WP 2.1 and 2.2" do
        expect(subjects).to contain_exactly(wp2_1.id, wp2_2.id)
      end
    end

    describe "case-insensitive matches" do
      let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=wp" }

      it "returns WP 2.1 and 2.2" do
        expect(subjects).to contain_exactly(wp2_1.id, wp2_2.id)
      end
    end

    describe "relation candidates for WP 2.2 (circular dependency check)" do
      let(:href) { "/api/v3/work_packages/#{wp2_2.id}/available_relation_candidates?query=WP" }

      it "returns just WP 2, not WP 2.1" do
        expect(subjects).to contain_exactly(wp2.id)
      end
    end
  end

  context "with cross project relations",
          with_settings: { cross_project_work_package_relations: true } do
    describe "relation candidates for wp1 (in hierarchy)" do
      let(:href) { "/api/v3/work_packages/#{wp1.id}/available_relation_candidates?query=WP" }

      it "returns WP 2 and all WP 2.x as well at the grandchild WP 1.2.1" do
        expect(subjects).to contain_exactly(wp2.id, wp2_1.id, wp2_2.id, wp1_2_1.id)
      end
    end

    describe "relation candidates for wp1 (in hierarchy) with typeahead sorting" do
      let(:href) { "/api/v3/work_packages/#{wp1.id}/available_relation_candidates?query=WP&sortBy=[[\"typeahead\", \"asc\"]]" }

      before do
        wp2_2.update_column(:updated_at, 10.days.ago)
        wp2.update_column(:updated_at, 5.days.ago)
      end

      it "returns WP 2 and all WP 2.x sorted by updated_at DESC" do
        expect(subjects).to match [wp2_1.id, wp1_2_1.id, wp2.id, wp2_2.id]
      end
    end

    describe "relation candidates for wp2" do
      let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP&type=follows" }

      it "returns WP 2.1 and 2.2, WP 1 and all WP 1.x" do
        expect(subjects).to contain_exactly(wp1.id, wp1_1.id, wp1_2.id, wp1_2_1.id, wp2_1.id, wp2_2.id)
      end

      describe "with an already existing relationship from the work package" do
        shared_let(:relation_wp2_to_wp2_2) do
          create(:relation, from: wp2, to: wp2_2, relation_type: "follows")
        end

        shared_let(:relation_wp1_1_to_wp2) do
          create(:relation, from: wp1_1, to: wp2, relation_type: "follows")
        end
        context "for a follows relationship" do
          it "does not contain the work packages already related in the opposite direction nor the parent" do
            expect(subjects).to contain_exactly(wp1_2.id, wp1_2_1.id, wp2_1.id)
          end
        end

        context "for a precedes relationship" do
          let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP&type=precedes" }

          it "does not contain the work packages already related but the parent" do
            expect(subjects).to contain_exactly(wp1.id, wp1_2.id, wp1_2_1.id, wp2_1.id)
          end
        end

        context "for a parent relationship" do
          let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP&type=parent" }

          it "does not contain the work packages already related but the parent" do
            expect(subjects).to contain_exactly(wp1.id, wp1_2.id, wp1_2_1.id, wp2_1.id)
          end
        end

        context "for a child relationship" do
          let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP&type=child" }

          it "does not contain the work packages already related nor the parent" do
            expect(subjects).to contain_exactly(wp1_2.id, wp1_2_1.id, wp2_1.id)
          end
        end

        context "for a relates relationship" do
          let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP&type=relates" }

          it "does not contain the work packages already related but the parent" do
            expect(subjects).to contain_exactly(wp1.id, wp1_2.id, wp1_2_1.id, wp2_1.id)
          end
        end
      end
    end

    context "when a project is archived" do
      let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP" }

      before do
        project1.update_column(:active, false)
      end

      it "does not return work packages from that project" do
        expect(subjects).to contain_exactly(wp2_1.id, wp2_2.id)
      end
    end
  end

  context "when the user is not an admin and has access to just one project" do
    let(:user) { create(:user, member_with_permissions: { project2 => %i[view_work_packages edit_work_packages] }) }
    let(:href) { "/api/v3/work_packages/#{wp2.id}/available_relation_candidates?query=WP" }

    it "only includes work packages from the first project" do
      expect(subjects).to contain_exactly(wp2_1.id, wp2_2.id)
    end
  end
end
