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
require_relative "shared_examples"

RSpec.describe Capabilities::Scopes::Visible do
  subject(:scope) { Capability.visible(user).where(principal_id: queried_user.id) }

  shared_let(:project) { create(:project, enabled_module_names: %i[]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[]) }
  shared_let(:queried_user, reload: true) { create(:user) }

  let(:role) { create(:project_role, permissions: %i[manage_members]) }
  let(:global_role) { create(:global_role, permissions: %i[manage_user]) }

  let(:queried_user_member) do
    create(:member,
           principal: queried_user,
           roles: [role],
           project:)
  end
  let(:queried_user_other_member) do
    create(:member,
           principal: queried_user,
           roles: [role],
           project: other_project)
  end
  let(:queried_user_global_member) do
    create(:global_member,
           principal: queried_user,
           roles: [global_role])
  end

  before do
    queried_user_member
    queried_user_other_member
    queried_user_global_member
  end

  describe ".visible" do
    context "with an admin user" do
      let(:user) { create(:admin) }

      include_examples "consists of contract actions", with: "all capabilities (project and global)" do
        let(:expected) do
          [
            ["memberships/create", queried_user.id, project.id],
            ["memberships/update", queried_user.id, project.id],
            ["memberships/destroy", queried_user.id, project.id],
            ["memberships/create", queried_user.id, other_project.id],
            ["memberships/update", queried_user.id, other_project.id],
            ["memberships/destroy", queried_user.id, other_project.id],
            ["users/read", queried_user.id, nil],
            ["users/update", queried_user.id, nil]
          ]
        end
      end
    end

    context "with a user having access to both projects" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 project => %i[],
                 other_project => %i[]
               })
      end

      include_examples "consists of contract actions", with: "all capabilities (project and global)" do
        let(:expected) do
          [
            ["memberships/create", queried_user.id, project.id],
            ["memberships/update", queried_user.id, project.id],
            ["memberships/destroy", queried_user.id, project.id],
            ["memberships/create", queried_user.id, other_project.id],
            ["memberships/update", queried_user.id, other_project.id],
            ["memberships/destroy", queried_user.id, other_project.id],
            ["users/read", queried_user.id, nil],
            ["users/update", queried_user.id, nil]
          ]
        end
      end
    end

    context "with a user having access to only one project" do
      let(:user) do
        create(:user,
               member_with_permissions: { project => %i[] })
      end

      include_examples "consists of contract actions", with: "only capabilities of that one project and global" do
        let(:expected) do
          [
            ["memberships/create", queried_user.id, project.id],
            ["memberships/update", queried_user.id, project.id],
            ["memberships/destroy", queried_user.id, project.id],
            ["users/read", queried_user.id, nil],
            ["users/update", queried_user.id, nil]
          ]
        end
      end
    end

    context "with a user having no project access but having the :view_all_principals permission" do
      let(:user) { create(:user, global_permissions: %i[view_all_principals]) }

      include_examples "consists of contract actions", with: "only global capabilities" do
        let(:expected) do
          [
            ["users/read", queried_user.id, nil],
            ["users/update", queried_user.id, nil]
          ]
        end
      end
    end

    context "with a user having no project access and also lacking the :view_all_principals permission" do
      let(:user) { create(:user) }

      include_examples "is empty"
    end

    context "with a user having access in an unrelated project but lacking the :view_all_principals permission" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 create(:project) => %i[]
               })
      end

      include_examples "is empty"
    end

    context "with the queried for user being locked" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 project => %i[],
                 other_project => %i[]
               },
               global_permissions: %i[view_all_principals])
      end

      before do
        queried_user.locked!
      end

      include_examples "is empty"
    end

    context "with the queried for user being the system user" do
      let(:user) do
        create(:user,
               global_permissions: %i[view_all_principals])
      end
      let(:queried_user) { User.system }

      include_examples "is empty"
    end
  end
end
