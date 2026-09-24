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

RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter, with_ee: %i[resource_management] do
  let(:enabled_modules) { %i[work_package_tracking resource_management] }
  let(:project) { create(:project, enabled_module_names: enabled_modules) }
  let(:permissions) { %i[view_work_packages view_resource_planners allocate_user_resources] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }

  subject(:generated) do
    described_class.create(work_package, current_user: user, embed_links: true).to_json
  end

  before { login_as(user) }

  describe "_links/allocateResource" do
    it "links to the new allocation dialog with the work package preselected" do
      expect(generated)
        .to be_json_eql(
          Rails.application.routes.url_helpers
            .new_project_resource_allocation_path(project, work_package_id: work_package.id).to_json
        ).at_path("_links/allocateResource/href")
    end

    it "is typed as a turbo stream" do
      expect(generated).to be_json_eql("text/vnd.turbo-stream.html".to_json).at_path("_links/allocateResource/type")
    end

    context "without the allocate_user_resources permission" do
      let(:permissions) { %i[view_work_packages view_resource_planners] }

      it { is_expected.not_to have_json_path("_links/allocateResource") }
    end

    context "with the resource management module disabled" do
      let(:enabled_modules) { %i[work_package_tracking] }

      it { is_expected.not_to have_json_path("_links/allocateResource") }
    end

    context "for a work package without a project" do
      let(:work_package) { build_stubbed(:work_package, project: nil) }

      it { is_expected.not_to have_json_path("_links/allocateResource") }
    end

    context "without an enterprise token", with_ee: false do
      it { is_expected.not_to have_json_path("_links/allocateResource") }
    end
  end

  describe "_links/showResourceAllocations" do
    it "links to the allocations dialog of the work package" do
      expect(generated)
        .to be_json_eql(
          Rails.application.routes.url_helpers
            .project_work_package_resource_allocations_path(project, work_package.id).to_json
        ).at_path("_links/showResourceAllocations/href")
    end

    it "is typed as a turbo stream" do
      expect(generated)
        .to be_json_eql("text/vnd.turbo-stream.html".to_json).at_path("_links/showResourceAllocations/type")
    end

    context "without the view_resource_planners permission" do
      let(:permissions) { %i[view_work_packages] }

      it { is_expected.not_to have_json_path("_links/showResourceAllocations") }
    end

    context "without an enterprise token", with_ee: false do
      it { is_expected.not_to have_json_path("_links/showResourceAllocations") }
    end
  end

  describe "allocatedTime" do
    before do
      create(:resource_allocation, entity: work_package, allocated_time: 8 * 60)
      create(:resource_allocation, entity: work_package, allocated_time: 90)
      create(:resource_allocation, :requested, entity: work_package, allocated_time: 4 * 60)
      create(:resource_allocation, allocated_time: 16 * 60)
    end

    it "sums the confirmed allocations of the work package" do
      expect(generated).to be_json_eql("PT9H30M".to_json).at_path("allocatedTime")
    end

    context "without any allocations" do
      before { ResourceAllocation.delete_all }

      it { is_expected.to be_json_eql("PT0S".to_json).at_path("allocatedTime") }
    end

    context "without the view_resource_planners permission" do
      let(:permissions) { %i[view_work_packages] }

      it { is_expected.not_to have_json_path("allocatedTime") }
    end

    context "without an enterprise token", with_ee: false do
      it { is_expected.not_to have_json_path("allocatedTime") }
    end
  end

  describe "_links/allocatedPrincipals" do
    let!(:user_allocation) { create(:resource_allocation, entity: work_package, principal: user) }
    let!(:placeholder_allocation) { create(:resource_allocation, :with_user_filter, entity: work_package) }

    it "links the allocated users and placeholders" do
      placeholder = placeholder_allocation.placeholder_user

      expect(generated)
        .to be_json_eql([
          { href: "/api/v3/users/#{user.id}", title: user.name },
          { href: "/api/v3/placeholder_users/#{placeholder.id}", title: placeholder.name }
        ].to_json).at_path("_links/allocatedPrincipals")
    end

    context "without the view_resource_planners permission" do
      let(:permissions) { %i[view_work_packages] }

      it { is_expected.not_to have_json_path("_links/allocatedPrincipals") }
    end

    context "without an enterprise token", with_ee: false do
      it { is_expected.not_to have_json_path("_links/allocatedPrincipals") }
    end
  end
end
