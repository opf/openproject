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

RSpec.describe "Setting a work package's security level" do # rubocop:disable RSpec/DescribeClass
  shared_let(:scheme) { create(:security_level_scheme) }
  shared_let(:other_scheme) { create(:security_level_scheme) }
  shared_let(:project) { create(:project, security_level_scheme: scheme) }
  shared_let(:internal) { create(:security_level, security_level_scheme: scheme, name: "Internal") }
  shared_let(:management) { create(:security_level, security_level_scheme: scheme, name: "Management") }
  shared_let(:foreign_level) { create(:security_level, security_level_scheme: other_scheme, name: "Foreign") }

  shared_let(:work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages edit_work_packages set_work_package_security_level] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { SecurityLevelPrincipal.create!(security_level: internal, principal: user) }

  def update(attributes)
    WorkPackages::UpdateService.new(user:, model: work_package.reload).call(**attributes)
  end

  it "accepts a level the user holds" do
    result = update(security_level_id: internal.id)

    expect(result).to be_success
    expect(work_package.reload.security_level).to eq internal
  end

  it "rejects a level the user does not hold" do
    result = update(security_level_id: management.id)

    expect(result).to be_failure
    expect(result.errors.symbols_for(:security_level)).to include(:inclusion)
  end

  it "rejects a level of another scheme" do
    result = update(security_level_id: foreign_level.id)

    expect(result).to be_failure
    expect(result.errors.symbols_for(:security_level)).to include(:not_in_project_scheme)
  end

  it "journals the change" do
    update(security_level_id: internal.id)

    expect(work_package.journals.last.details).to include("security_level_id" => [nil, internal.id])
  end

  context "without the permission to set levels" do
    let(:permissions) { %i[view_work_packages edit_work_packages] }

    it "rejects the change" do
      result = update(security_level_id: internal.id)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:security_level_id)).to include(:error_readonly)
    end
  end

  context "when the project uses no scheme" do
    let(:other_project) { create(:project) }
    let(:other_work_package) { create(:work_package, project: other_project) }
    let(:user) { create(:admin) }

    it "offers no level" do
      contract = WorkPackages::UpdateContract.new(other_work_package, user)

      expect(contract.assignable_security_levels).to be_empty
      expect(contract.writable?(:security_level_id)).to be false
    end
  end

  describe "assignable levels" do
    it "are the scheme's levels the user holds" do
      contract = WorkPackages::UpdateContract.new(work_package, user)

      expect(contract.assignable_security_levels).to contain_exactly(internal)
    end

    it "are all of the scheme's levels for admins" do
      contract = WorkPackages::UpdateContract.new(work_package, create(:admin))

      expect(contract.assignable_security_levels).to contain_exactly(internal, management)
    end
  end

  describe "moving to another project" do
    let(:user) { create(:admin) }
    let(:target_scheme) { create(:security_level_scheme) }
    let!(:target_internal) { create(:security_level, security_level_scheme: target_scheme, name: "Internal") }
    let(:target_project) { create(:project, security_level_scheme: target_scheme, types: [work_package.type]) }

    before { work_package.update_column(:security_level_id, internal.id) }

    it "takes the level of the same name in the target scheme" do
      result = update(project: target_project)

      expect(result).to be_success
      expect(work_package.reload.security_level).to eq target_internal
    end

    it "refuses the move when the target scheme has no such level" do
      work_package.update_column(:security_level_id, management.id)

      result = update(project: target_project)

      expect(result).to be_failure
      expect(result.errors.symbols_for(:security_level)).to include(:not_in_project_scheme)
    end
  end
end
