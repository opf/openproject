#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Capabilities::Scopes::Default, type: :model do
  subject(:scope) { Capability.default }

  let(:permissions) { %i[] }
  let(:global_permissions) { %i[] }
  let(:non_member_permissions) { %i[] }
  let(:project_public) { false }
  let!(:project) { FactoryBot.create(:project, public: project_public) }
  let(:role) do
    FactoryBot.create(:role, permissions: permissions)
  end
  let(:global_role) do
    FactoryBot.create(:global_role, permissions: global_permissions)
  end
  let!(:user) { FactoryBot.create(:user) }
  let(:global_member) do
    FactoryBot.create(:global_member,
                      principal: user,
                      roles: [global_role])
  end
  let(:member) do
    FactoryBot.create(:member,
                      principal: user,
                      roles: [role],
                      project: project)
  end
  let(:non_member_role) do
    FactoryBot.create(:non_member,
                      permissions: non_member_permissions)
  end

  shared_examples_for 'consists of contract actions' do
    it 'includes the expected' do
      expect(scope.pluck(:permission_map, :principal_id, :context_id))
        .to match_array(expected)
    end
  end

  shared_examples_for 'is empty' do
    it 'is empty' do
      expect(scope)
        .to be_empty
    end
  end

  describe '.fetch' do
    before do
      members
    end

    context 'without any members and non member roles' do
      let(:members) { [] }

      it_behaves_like 'is empty'
    end

    context 'with a member without a permission' do
      let(:members) { [member] }

      it_behaves_like 'is empty'
    end

    context 'with a global member without a permission' do
      let(:members) { [global_member] }

      it_behaves_like 'is empty'
    end

    context 'with a non member role without a permission' do
      let(:members) { [non_member_role] }

      it_behaves_like 'is empty'
    end

    context 'with a global member with an action permission' do
      let(:global_permissions) { %i[manage_user] }
      let(:members) { [global_member] }

      it_behaves_like 'consists of contract actions' do
        let(:expected) do
          [['users/create', user.id, nil],
           ['users/read', user.id, nil],
           ['users/update', user.id, nil]]
        end
      end
    end

    context 'with a member with an action permission' do
      let(:permissions) { %i[manage_members] }
      let(:members) { [member] }

      it_behaves_like 'consists of contract actions' do
        let(:expected) do
          [['memberships/create', user.id, project.id],
           ['memberships/destroy', user.id, project.id],
           ['memberships/update', user.id, project.id]]
        end
      end
    end

    context 'with the non member role with an action permission' do
      let(:non_member_permissions) { %i[view_members] }
      let(:members) { [non_member_role] }

      context 'with the project being private' do
        it_behaves_like 'is empty'
      end

      context 'with the project being public' do
        let(:project_public) { true }

        it_behaves_like 'consists of contract actions' do
          let(:expected) do
            [['memberships/read', user.id, project.id]]
          end
        end
      end
    end

    context 'with a member without a permission and with the non member having a permission' do
      let(:non_member_permissions) { %i[view_members] }
      let(:members) { [member, non_member_role] }

      it_behaves_like 'consists of contract actions' do
        let(:expected) do
          [['memberships/read', user.id, project.id]]
        end
      end
    end

    context 'with a member with a permission and with the non member having the same permission' do
      let(:non_member_permissions) { %i[view_members] }
      let(:member_permissions) { %i[view_members] }
      let(:members) { [member, non_member_role] }

      it_behaves_like 'consists of contract actions' do
        let(:expected) do
          [['memberships/read', user.id, project.id]]
        end
      end
    end

    # TODO: administrators should have every capability in every project
    # TODO: factor in enabled modules? yes
  end
end
