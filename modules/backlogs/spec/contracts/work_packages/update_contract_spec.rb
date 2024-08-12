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

RSpec.describe WorkPackages::UpdateContract do
  let(:work_package) do
    create(:work_package,
           done_ratio: 50,
           estimated_hours: 6.0,
           project:)
  end
  let(:member) { create(:user, member_with_roles: { project => role }) }
  let(:project) { create(:project) }
  let(:current_user) { member }
  let(:permissions) do
    %i[
      view_work_packages
      view_work_package_watchers
      edit_work_packages
      add_work_package_watchers
      delete_work_package_watchers
      manage_work_package_relations
      add_work_package_notes
    ]
  end
  let(:role) { create(:project_role, permissions:) }
  let(:changed_values) { [] }

  subject(:contract) { described_class.new(work_package, current_user) }

  before do
    allow(work_package).to receive(:changed).and_return(changed_values)
  end

  describe "story points" do
    context "has not changed" do
      it("is valid") { expect(contract.errors.empty?).to be true }
    end

    context "has changed" do
      let(:changed_values) { ["story_points"] }

      it("is valid") { expect(contract.errors.empty?).to be true }
    end
  end
end
