#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe MembersController, type: :controller do
  using_shared_fixtures :admin
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project, identifier: 'pet_project') }
  let(:role) { FactoryBot.create(:role) }
  let(:member) {
    FactoryBot.create(:member, project: project,
                                user: user,
                                roles: [role])
  }

  before do
    allow(User).to receive(:current).and_return(admin)
  end

  describe 'create' do
    using_shared_fixtures :admin
    let(:project_2) { FactoryBot.create(:project) }

    before do
      allow(User).to receive(:current).and_return(admin)
    end

    it 'should work for multiple users' do
      post :create,
           params: {
             project_id: project_2.identifier,
             member: {
               user_ids: [admin.id, user.id],
               role_ids: [role.id]
             }
           }

      expect(response.response_code).to be < 400

      [admin, user].each do |u|
        u.reload
        expect(u.memberships.size).to be >= 1

        expect(u.memberships.find { |m|
          expect(m.roles).to include(role)
        }).not_to be_nil
      end
    end
  end

  describe 'update' do
    using_shared_fixtures :admin
    let(:project_2) { FactoryBot.create(:project) }
    let(:role_1) { FactoryBot.create(:role) }
    let(:role_2) { FactoryBot.create(:role) }
    let(:member_2) do
      FactoryBot.create(
        :member,
        project: project_2,
        user: admin,
        roles: [role_1])
    end

    before do
      allow(User).to receive(:current).and_return(admin)
    end

    it 'should, however, allow roles to be updated through mass assignment' do
      put 'update',
          params: {
            project_id: project.identifier,
            id: member_2.id,
            member: {
              role_ids: [role_1.id, role_2.id]
            }
          }

      expect(Member.find(member_2.id).roles).to include(role_1, role_2)
      expect(response.response_code).to be < 400
    end
  end

  describe '#autocomplete_for_member' do
    let(:params) { { 'project_id' => project.identifier.to_s } }

    before do
      login_as(user)
    end

    describe "WHEN the user is authorized
              WHEN a project is provided" do
      before do
        role.add_permission! :manage_members
        member
      end

      it 'should be success' do
        post :autocomplete_for_member, xhr: true, params: params
        expect(response).to be_successful
      end
    end

    describe 'WHEN the user is not authorized' do
      it 'should be forbidden' do
        post :autocomplete_for_member, xhr: true, params: params
        expect(response.response_code).to eq(403)
      end
    end
  end

  describe '#create' do
    render_views
    let(:user2) { FactoryBot.create(:user) }
    let(:user3) { FactoryBot.create(:user) }
    let(:user4) { FactoryBot.create(:user) }

    context 'post :create' do
      context 'single member' do
        let(:action) do
          post :create,
               params: {
                 project_id: project.id,
                 member: { role_ids: [role.id], user_id: user2.id }
               }
        end

        it 'should add a member' do
          expect { action }.to change { Member.count }.by(1)
          expect(response).to redirect_to '/projects/pet_project/members?status=all'
          expect(user2).to be_member_of(project)
        end
      end

      context 'multiple members' do
        let(:action) do
          post :create,
               params: {
                 project_id: project.id,
                 member: { role_ids: [role.id], user_ids: [user2.id, user3.id, user4.id] }
               }
        end

        it 'should add all members' do
          expect { action }.to change { Member.count }.by(3)
          expect(response).to redirect_to '/projects/pet_project/members?status=all'
          expect(user2).to be_member_of(project)
          expect(user3).to be_member_of(project)
          expect(user4).to be_member_of(project)
        end
      end
    end

    context 'with a failed save' do
      let(:invalid_params) do
        { project_id: project.id,
          member: { role_ids: [],
                    user_ids: [user2.id, user3.id, user4.id] } }
      end

      before do
        post :create, params: invalid_params
      end

      it 'should not redirect to the members index' do
        expect(response).not_to redirect_to '/projects/pet_project/members'
      end

      it 'should show an error message' do
        expect(response.body).to include 'Roles need to be assigned.'
      end
    end
  end

  describe '#destroy' do
    let(:action) { post :destroy, params: { id: member.id } }
    before do
      member
    end

    it 'should destroy a member' do
      expect { action }.to change { Member.count }.by(-1)
      expect(response).to redirect_to '/projects/pet_project/members'
      expect(user).not_to be_member_of(project)
    end
  end

  describe '#update' do
    let(:action) {
      post :update,
           params: {
             id: member.id,
             member: { role_ids: [role2.id], user_id: user.id }
           }
    }
    let(:role2) { FactoryBot.create(:role) }

    before do
      member
    end

    it 'should update the member' do
      expect { action }.not_to change { Member.count }
      expect(response).to redirect_to '/projects/pet_project/members'
    end
  end
end
