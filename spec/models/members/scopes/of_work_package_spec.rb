# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Members::Scopes::OfWorkPackage do
  let(:project) { create(:project) }
  let(:work_package_role) { create(:view_work_package_role) }
  let(:role) { create(:project_role) }
  let(:user) { create(:user) }
  let(:work_package) { create(:work_package, project:) }
  let(:other_work_package) { create(:work_package, project:) }

  let!(:project_member) do
    create(:member,
           project:,
           roles: [role],
           principal: user)
  end
  let!(:work_package_member) do
    create(:member,
           project:,
           roles: [work_package_role],
           entity: work_package,
           principal: user)
  end
  let!(:other_work_package_member) do
    create(:member,
           project:,
           roles: [work_package_role],
           entity: other_work_package,
           principal: user)
  end
  let!(:global_member) do
    create(:global_member,
           roles: [create(:global_role)],
           principal: user)
  end

  describe ".of_work_package" do
    subject { Member.of_work_package(work_package) }

    it "returns memberships on the specific work package" do
      expect(subject)
        .to contain_exactly(work_package_member)
    end
  end
end
