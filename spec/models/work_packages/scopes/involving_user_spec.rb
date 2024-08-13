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

RSpec.describe WorkPackages::Scopes::InvolvingUser do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:user) do
    create(
      :user,
      # project_with_types is from create_shared_association_defaults_for_work_package_factory helper
      member_with_permissions: { project_with_types => %i[view_work_packages] }
    )
  end

  it "returns work packages for which a user is assigned to" do
    _work_package_blank = create(:work_package)
    work_package_assigned1 = create(:work_package, assigned_to: user)
    work_package_assigned2 = create(:work_package, assigned_to: user)

    expect(WorkPackage.involving_user(user))
      .to contain_exactly(work_package_assigned1, work_package_assigned2)
  end

  it "returns work packages for which a user is accountable / responsible" do
    _work_package_blank = create(:work_package)
    work_package_responsible1 = create(:work_package, responsible: user)
    work_package_responsible2 = create(:work_package, responsible: user)

    expect(WorkPackage.involving_user(user))
      .to contain_exactly(work_package_responsible1, work_package_responsible2)
  end

  it "returns work packages for which a user is a watcher" do
    _work_package_blank = create(:work_package)
    work_package_watched1 = create(:work_package)
    create(:watcher, watchable: work_package_watched1, user:)
    work_package_watched2 = create(:work_package)
    create(:watcher, watchable: work_package_watched2, user:)

    expect(WorkPackage.involving_user(user))
      .to contain_exactly(work_package_watched1, work_package_watched2)
  end

  context "when user is part of a group" do
    shared_let(:group) { create(:group, members: [user]) }

    it "returns work packages for which the group is assigned to" do
      _work_package_blank = create(:work_package)
      work_package_assigned = create(:work_package, assigned_to: group)

      expect(WorkPackage.involving_user(user))
        .to contain_exactly(work_package_assigned)
    end

    it "returns work packages for which the group is accountable / responsible" do
      _work_package_blank = create(:work_package)
      work_package_responsible = create(:work_package, responsible: group)

      expect(WorkPackage.involving_user(user))
        .to contain_exactly(work_package_responsible)
    end
  end
end
