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

RSpec.describe Projects::Types::SwitchSubtypeService, with_flag: { subtypes: true } do
  subject(:service_call) { described_class.new(user:, model: project).call(source:, target:) }

  let(:user) { create(:admin) }
  let(:parent_type) { create(:type) }
  let(:subtype) { create(:type, parent: parent_type) }
  let(:sibling_subtype) { create(:type, parent: parent_type) }
  let(:project) { create(:project, types: [subtype]) }
  let!(:work_package) { create(:work_package, project:, type: subtype) }

  let(:source) { subtype }
  let(:target) { sibling_subtype }

  context "when switching to a sibling subtype" do
    it "moves the work packages, enables the target and removes the source" do
      expect(service_call).to be_success
      expect(work_package.reload.type).to eq(sibling_subtype)
      expect(project.reload.types).to contain_exactly(sibling_subtype)
    end
  end

  context "when switching to the parent type" do
    let(:target) { parent_type }

    it "moves the work packages to the parent and swaps the enabled types" do
      expect(service_call).to be_success
      expect(work_package.reload.type).to eq(parent_type)
      expect(project.reload.types).to contain_exactly(parent_type)
    end
  end

  context "when the source is not a subtype" do
    let(:source) { parent_type }
    let(:target) { subtype }

    it "fails without changing anything" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_source_not_a_subtype)
      expect(work_package.reload.type).to eq(subtype)
      expect(project.reload.types).to contain_exactly(subtype)
    end
  end

  context "when the target is identical to the source" do
    let(:target) { subtype }

    it "fails" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_target_identical)
    end
  end

  context "when the target belongs to a different family" do
    let(:target) { create(:type, parent: create(:type)) }

    it "fails" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:types)).to contain_exactly(:switch_target_not_in_family)
    end
  end

  context "when the user is not allowed to manage types" do
    let(:user) { create(:user) }

    it "fails without changing anything" do
      expect(service_call).to be_failure
      expect(service_call.errors.symbols_for(:base)).to contain_exactly(:error_unauthorized)
      expect(work_package.reload.type).to eq(subtype)
      expect(project.reload.types).to contain_exactly(subtype)
    end
  end

  context "when a work package fails to update" do
    before do
      failing_service = instance_double(WorkPackages::UpdateService, call: ServiceResult.failure)
      allow(WorkPackages::UpdateService).to receive(:new).and_return(failing_service)
    end

    it "rolls back the entire switch" do
      expect(service_call).to be_failure
      expect(work_package.reload.type).to eq(subtype)
      expect(project.reload.types).to contain_exactly(subtype)
    end
  end
end
