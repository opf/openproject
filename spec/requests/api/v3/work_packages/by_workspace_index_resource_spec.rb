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

require "spec_helper"
require "rack/test"

RSpec.describe "GET api/v3/workspace/:id/work_packages", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, :with_types) }
  shared_let(:portfolio) { create(:portfolio, :with_types) }

  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:view_work_packages] }
  let(:query) { {} }
  let(:path) { "#{base_path}?#{query.to_query}" }
  let(:work_packages) { [] }

  current_user do
    create(:user, member_with_roles: {
             project => role,
             portfolio => role
           })
  end

  subject { last_response }

  before do
    work_packages.each(&:save!)
    get path
  end

  shared_context "with work package indexing" do
    it "succeeds" do
      expect(subject.status).to eq 200
    end

    context "when not allowed to see the project" do
      let(:current_user) { create(:user) }

      it "fails with HTTP Not Found" do
        expect(subject.status).to eq 404
      end
    end

    context "when not allowed to see work packages" do
      let(:permissions) { [:view_project] }

      it "fails with HTTP Not Found" do
        expect(subject.status).to eq 403
      end
    end

    describe "sorting" do
      let(:query) { { sortBy: '[["id", "desc"]]' } }
      let(:work_packages) { create_list(:work_package, 2, project: workspace) }

      it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { work_packages.reverse }
      end
    end

    describe "filtering by priority" do
      let(:query) do
        {
          filters: [
            {
              priority: {
                operator: "=",
                values: [priority1.id.to_s]
              }
            }
          ].to_json
        }
      end
      let(:priority1) { create(:priority, name: "Prio A") }
      let(:priority2) { create(:priority, name: "Prio B") }
      let(:work_packages) do
        [
          create(:work_package, project: workspace, priority: priority1),
          create(:work_package, project: workspace, priority: priority2)
        ]
      end

      it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_packages.first] }
      end
    end

    describe "filtering by project (one different from the project of the path)" do
      let(:query) do
        {
          filters: [
            {
              project: {
                operator: "=",
                values: [other_project.id.to_s]
              }
            }
          ].to_json
        }
      end
      let(:other_project) { create(:project, members: { current_user => role }) }
      let(:work_packages) { [other_project_work_package, project_work_package] }
      let(:project_work_package) { create(:work_package, project: workspace) }
      let(:other_project_work_package) { create(:work_package, project: other_project) }

      it_behaves_like "API V3 collection response", 1, 1, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [other_project_work_package] }
      end
    end

    describe "grouping" do
      let(:query) { { groupBy: "priority" } }
      let(:priority1) { build(:priority, name: "Prio A", position: 2) }
      let(:priority2) { build(:priority, name: "Prio B", position: 1) }
      let(:work_packages) do
        [
          create(:work_package,
                 project: workspace,
                 priority: priority1,
                 estimated_hours: 1),
          create(:work_package,
                 project: workspace,
                 priority: priority2,
                 estimated_hours: 2),
          create(:work_package,
                 project: workspace,
                 priority: priority1,
                 estimated_hours: 3)
        ]
      end
      let(:expected_group1) do
        {
          _links: {
            valueLink: [{
              href: api_v3_paths.priority(priority1.id)
            }],
            groupBy: {
              href: api_v3_paths.query_group_by("priority"),
              title: "Priority"
            }
          },
          value: priority1.name,
          count: 2
        }
      end
      let(:expected_group2) do
        {
          _links: {
            valueLink: [{
              href: api_v3_paths.priority(priority2.id)
            }],
            groupBy: {
              href: api_v3_paths.query_group_by("priority"),
              title: "Priority"
            }
          },
          value: priority2.name,
          count: 1
        }
      end

      it_behaves_like "API V3 collection response", 3, 3, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { [work_packages.second, work_packages.first, work_packages.third] }
      end

      it "contains group elements" do
        expect(subject.body).to include_json(expected_group1.to_json).at_path("groups")
        expect(subject.body).to include_json(expected_group2.to_json).at_path("groups")
      end
    end

    describe "displaying sums" do
      let(:query) { { showSums: "true" } }
      let(:work_packages) do
        [
          create(:work_package, project: workspace, estimated_hours: 1),
          create(:work_package, project: workspace, estimated_hours: 2)
        ]
      end

      it_behaves_like "API V3 collection response", 2, 2, "WorkPackage", "WorkPackageCollection" do
        let(:elements) { work_packages }
      end

      it "contains the sum element" do
        expected = {
          estimatedTime: "PT3H",
          laborCosts: "0.00 €",
          materialCosts: "0.00 €",
          overallCosts: "0.00 €",
          percentageDone: nil,
          remainingTime: nil,
          storyPoints: nil
        }

        expect(subject.body).to be_json_eql(expected.to_json).at_path("totalSums")
      end

      describe "percentageDone/done_ratio sum" do
        let(:work_package) { create(:work_package, project: workspace, **hours) }
        let(:work_packages) { [work_package] }

        subject(:percentage_done_sum) { JSON.parse(last_response.body)["totalSums"]["percentageDone"] }

        context "when work sum and remaining work sum are not set" do
          let(:hours) { {} }

          it "is not set" do
            expect(percentage_done_sum).to be_nil
          end
        end

        context "when work sum and remaining work sum are set to valid values (W=10h, RW=4h)" do
          let(:hours) { { estimated_hours: 10, remaining_hours: 4 } }

          it "is calculated from them (60%)" do
            expect(percentage_done_sum).to eq 60
          end
        end

        context "when only work sum is set" do
          let(:hours) { { estimated_hours: 10 } }

          it "is not set" do
            expect(percentage_done_sum).to be_nil
          end
        end

        context "when only remaining work sum is set" do
          let(:hours) { { remaining_hours: 4 } }

          it "is not set" do
            expect(percentage_done_sum).to be_nil
          end
        end

        context "when work sum and remaining work sum are 0h" do
          let(:hours) { { estimated_hours: 0, remaining_hours: 0 } }

          it "is not set" do
            expect(percentage_done_sum).to be_nil
          end
        end

        context "when remaining work sum is greater than work sum (bad data, like W=10h RW=15h)" do
          let(:hours) { { estimated_hours: 10, remaining_hours: 15 } }

          it "is set to 0% (and not -50%)" do
            expect(percentage_done_sum).to eq 0
          end
        end

        context "when remaining work sum is 0h and work sum is positive" do
          let(:hours) { { estimated_hours: 10, remaining_hours: 0 } }

          it "is set to 100%" do
            expect(percentage_done_sum).to eq 100
          end
        end

        context "when calculated % complete sum is xx.5% (like 50.5% or 42.5%)" do
          let(:hours) { { estimated_hours: 1000, remaining_hours: 495 } }

          it "is rounded up (like 51% or 43%)" do
            expect(percentage_done_sum).to eq 51
          end
        end

        context "when calculated % complete sum is almost 0% (like 0.4% or 0.01%)" do
          let(:hours) { { estimated_hours: 1000, remaining_hours: 999 } }

          it "is rounded to 1% (because 0% would be wrong)" do
            expect(percentage_done_sum).to eq 1
          end
        end

        context "when % complete sum is almost 100% (like 99.5% or 99.99%)" do
          let(:hours) { { estimated_hours: 1000, remaining_hours: 1 } }

          it "is rounded to 99% (because 100% would be wrong)" do
            expect(percentage_done_sum).to eq 99
          end
        end
      end
    end
  end

  context "for a project path" do
    context "within a project" do
      let(:base_path) { api_v3_paths.work_packages_by_project project.id }
      let(:workspace) { project }

      include_context "with work package indexing"
    end

    context "within a portfolio" do
      let(:base_path) { api_v3_paths.work_packages_by_project portfolio.id }
      let(:workspace) { portfolio }

      include_context "with work package indexing"
    end
  end

  context "for a workspace path" do
    let(:base_path) { api_v3_paths.work_packages_by_workspace portfolio.id }
    let(:workspace) { portfolio }

    include_context "with work package indexing"
  end
end
