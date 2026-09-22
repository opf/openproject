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

RSpec.describe WorkPackage, ".allowed_to_via_share_only" do # rubocop:disable RSpec/SpecFilePathFormat
  subject { described_class.allowed_to_via_share_only(user, action) }

  shared_let(:action) { :view_work_packages }

  shared_let(:user) { create(:user) }
  shared_let(:project) { create(:project, public: false) }
  shared_let(:shared_work_package) { create(:work_package, project:, subject: "shared") }
  shared_let(:other_work_package) { create(:work_package, project:, subject: "other") }

  let(:work_package_role) { create(:work_package_role, permissions: [action]) }

  def share(work_package, with: user, roles: [work_package_role])
    create(:member, project: work_package.project, entity: work_package, user: with, roles:)
  end

  context "when the work package is shared with the user" do
    before { share(shared_work_package) }

    it "returns only that work package" do
      expect(subject).to contain_exactly(shared_work_package)
    end
  end

  context "when the user is a member of the project instead" do
    before do
      create(:member, project:, user:, roles: [create(:project_role, permissions: [action])])
    end

    it "returns nothing, because project membership is not a share" do
      expect(subject).to be_empty
    end
  end

  context "when the work package is shared and the project is visible too" do
    before do
      create(:member, project:, user:, roles: [create(:project_role, permissions: [action])])
      share(shared_work_package)
    end

    it "still returns the shared work package" do
      expect(subject).to contain_exactly(shared_work_package)
    end
  end

  context "when the share grants a different permission" do
    let(:work_package_role) { create(:work_package_role, permissions: [:edit_work_packages]) }

    before { share(shared_work_package) }

    it { is_expected.to be_empty }
  end

  context "when the work package is shared with somebody else" do
    before { share(shared_work_package, with: create(:user)) }

    it { is_expected.to be_empty }
  end

  context "when the sharing project is archived" do
    before do
      share(shared_work_package)
      project.update_column(:active, false)
    end

    it { is_expected.to be_empty }
  end

  context "when the work package tracking module is disabled" do
    before do
      share(shared_work_package)
      project.enabled_modules.where(name: "work_package_tracking").destroy_all
    end

    it { is_expected.to be_empty }
  end

  context "with a locked user" do
    let(:user) { create(:user, status: :locked) }

    before { share(shared_work_package) }

    it "returns nothing, since the membership relation does not check user status" do
      expect(subject).to be_empty
    end
  end

  context "with an admin holding no share" do
    let(:user) { create(:admin) }

    it "returns nothing, since being an admin is not a share" do
      expect(subject).to be_empty
    end
  end

  context "with an anonymous user" do
    let(:user) { create(:anonymous) }

    it { is_expected.to be_empty }
  end

  context "when the share is granted through a group" do
    shared_let(:group) { create(:group, members: [user]) }

    before do
      # Going through the service is what propagates the share to the group's users;
      # creating the member directly would leave the group row on its own.
      Members::CreateService
        .new(user: create(:admin), contract_class: EmptyContract)
        .call(principal: group,
              project_id: project.id,
              entity: shared_work_package,
              role_ids: [work_package_role.id])
    end

    it "returns the work package, because the group share is materialised per user" do
      expect(subject).to contain_exactly(shared_work_package)
    end
  end
end
