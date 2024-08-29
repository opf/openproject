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

RSpec.describe Queries::Principals::PrincipalQuery, "integration" do
  let(:current_user) { create(:user) }
  let(:instance) { described_class.new }
  let!(:non_member_role) { create(:non_member) }

  before do
    login_as(current_user)
  end

  context "with a member filter" do
    let(:project) { create(:project, public: true) }
    let(:role) { create(:project_role) }
    let(:project_user) do
      create(:user,
             member_with_roles: { project => role }) do |u|
        # Granting another membership in order to better test the "not" filter
        create(:member,
               principal: u,
               project: other_project,
               roles: [role])
      end
    end
    let(:other_project) { create(:project, public: true) }
    let(:other_project_user) do
      create(:user,
             member_with_roles: { other_project => role })
    end

    let(:users) { [current_user, project_user, other_project_user] }

    before do
      users
    end

    context "with the = operator" do
      before do
        instance.where("member", "=", [project.id.to_s])
      end

      it "returns all principals being member" do
        expect(instance.results)
          .to contain_exactly(project_user)
      end
    end

    context "with the ! operator" do
      before do
        instance.where("member", "!", [project.id.to_s])
      end

      it "returns all principals not being member" do
        expect(instance.results)
          .to contain_exactly(current_user, other_project_user)
      end
    end
  end
end
