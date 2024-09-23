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

RSpec.describe SharingStrategies::WorkPackageStrategy do
  let(:project) { build_stubbed(:project) }
  let(:entity) { build_stubbed(:work_package, project:) }
  let(:user) { build_stubbed(:user) }
  let(:query_params) { {} }
  let(:strategy) { described_class.new(entity, query_params:, user:) }

  shared_let(:view_work_package_role) { create(:view_work_package_role) }
  shared_let(:comment_work_package_role) { create(:comment_work_package_role) }
  shared_let(:edit_work_package_role) { create(:edit_work_package_role) }

  describe "#available_roles" do
    it "returns the appropriate role hash collection" do
      available_roles = strategy.available_roles
      expect(available_roles).to contain_exactly(
        {
          label: "Edit",
          value: edit_work_package_role.id,
          description: "Can view, comment and edit this work package."
        }, {
          label: "Comment",
          value: comment_work_package_role.id,
          description: "Can view and comment this work package."
        }, {
          label: "View",
          value: view_work_package_role.id,
          description: "Can view this work package.",
          default: true
        }
      )
    end
  end

  describe "#manageable?" do
    context "with permissions to share the work package" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :share_work_packages, project:
        end
      end

      it { expect(strategy).to be_manageable }
    end

    context "without permissions to share the work package" do
      it { expect(strategy).not_to be_manageable }
    end
  end

  describe "#viewable?" do
    context "with permissions to view the work package shares" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project :view_shared_work_packages, project:
        end
      end

      it { expect(strategy).to be_viewable }
    end

    context "without permissions to view the work package shares" do
      it { expect(strategy).not_to be_viewable }
    end
  end

  describe "#create_contract_class" do
    it { expect(strategy.create_contract_class).to eq(Shares::WorkPackages::CreateContract) }
  end

  describe "#update_contract_class" do
    it { expect(strategy.update_contract_class).to eq(Shares::WorkPackages::UpdateContract) }
  end

  describe "#delete_contract_class" do
    it { expect(strategy.delete_contract_class).to eq(Shares::WorkPackages::DeleteContract) }
  end

  describe "#empty_state_component" do
    it { expect(strategy.empty_state_component).to be_nil }
  end
end
