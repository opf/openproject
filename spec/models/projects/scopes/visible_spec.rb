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

RSpec.describe Projects::Scopes::Visible do
  shared_let(:activity) { create(:time_entry_activity) }
  shared_let(:project) { create(:project) }
  shared_let(:public_project) { create(:public_project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:shared_in_project) { create(:project) }
  shared_let(:shared_work_package) { create(:work_package, project: shared_in_project) }
  shared_let(:view_work_package_role) { create(:view_work_package_role) }
  shared_let(:non_member_role) { create(:non_member) }
  shared_let(:anonymous_role) { create(:anonymous_role) }
  shared_let(:shared_user) do
    create(:user).tap do |u|
      create(:member,
             project:,
             principal: u,
             roles: [create(:project_role)])

      create(:work_package_member,
             entity: shared_work_package,
             principal: u,
             roles: [view_work_package_role])
    end
  end
  shared_let(:admin_user) { create(:admin) }
  shared_let(:only_project_user) do
    create(:user).tap do |u|
      create(:member,
             project:,
             principal: u,
             roles: [create(:project_role)])
    end
  end
  shared_let(:only_shared_user) do
    create(:user).tap do |u|
      create(:work_package_member,
             entity: shared_work_package,
             principal: u,
             roles: [view_work_package_role])
    end
  end
  shared_let(:no_membership_user) do
    create(:user)
  end

  subject { Project.visible(current_user) }

  context "for an admin user" do
    let(:current_user) { admin_user }

    it "list all projects" do
      expect(subject).to contain_exactly(shared_in_project, project, public_project)
    end
  end

  context "for a user a work package is shared with and who has a memberships" do
    let(:current_user) { shared_user }

    it "list all projects" do
      expect(subject).to contain_exactly(shared_in_project, project, public_project)
    end
  end

  context "for a user having only a project membership" do
    let(:current_user) { only_project_user }

    it "list only the project in which the user has the membership and the public project" do
      expect(subject).to contain_exactly(project, public_project)
    end
  end

  context "for a user only having a share" do
    let(:current_user) { only_shared_user }

    it "list only the project in which the shared work package is and the public project" do
      expect(subject).to contain_exactly(shared_in_project, public_project)
    end
  end

  context "for a user without any permission" do
    let(:current_user) { no_membership_user }

    it "list only the public project" do
      expect(subject).to contain_exactly(public_project)
    end
  end

  context "for an anonymous user" do
    let(:current_user) { create(:anonymous) }

    it "list only the public project" do
      expect(subject).to contain_exactly(public_project)
    end
  end
end
