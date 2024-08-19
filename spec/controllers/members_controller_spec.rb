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

RSpec.describe MembersController do
  shared_let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:project) { create(:project, identifier: "pet_project") }
  let(:role) { create(:project_role) }
  let(:member) do
    create(:member, project:,
                    user:,
                    roles: [role])
  end

  before { login_as(admin) }

  describe "create" do
    shared_let(:admin) { create(:admin) }
    let(:project2) { create(:project) }

    it "works for multiple users" do
      post :create,
           params: {
             project_id: project2.identifier,
             member: {
               user_ids: [admin.id, user.id],
               role_ids: [role.id]
             }
           }

      expect(response.response_code).to be < 400

      [admin, user].each do |u|
        u.reload
        expect(u.memberships.size).to be >= 1

        expect(u.memberships.find do |m|
          expect(m.roles).to include(role)
        end).not_to be_nil
      end
    end
  end

  describe "update" do
    shared_let(:admin) { create(:admin) }
    let(:project2) { create(:project) }
    let(:role1) { create(:project_role) }
    let(:role2) { create(:project_role) }
    let(:member2) do
      create(
        :member,
        project: project2,
        user: admin,
        roles: [role1]
      )
    end

    it "however allows roles to be updated through mass assignment" do
      put "update",
          params: {
            project_id: project.identifier,
            id: member2.id,
            member: {
              role_ids: [role1.id, role2.id]
            }
          }

      expect(Member.find(member2.id).roles).to include(role1, role2)
      expect(response.response_code).to be < 400
    end
  end

  describe "#autocomplete_for_member" do
    let(:params) { { "project_id" => project.identifier.to_s } }

    before { login_as(user) }

    describe "WHEN the user is authorized WHEN a project is provided" do
      before do
        role.add_permission! :manage_members
        member
      end

      it "is success" do
        post(:autocomplete_for_member, xhr: true, params:)
        expect(response).to be_successful
      end
    end

    describe "WHEN the user is not authorized" do
      it "is forbidden" do
        post(:autocomplete_for_member, xhr: true, params:)
        expect(response.response_code).to eq(403)
      end
    end
  end

  describe "#create" do
    render_views
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:user4) { create(:user) }

    context "for single member" do
      let(:action) do
        post :create,
             params: {
               project_id: project.id,
               member: { role_ids: [role.id], user_id: user2.id }
             }
      end

      it "adds a member" do
        expect { action }.to change(Member, :count).by(1)
        expect(response).to redirect_to "/projects/pet_project/members?status=all"
        expect(user2).to be_member_of(project)
      end
    end

    context "for multiple members" do
      let(:action) do
        post :create,
             params: {
               project_id: project.id,
               member: { role_ids: [role.id], user_ids: [user2.id, user3.id, user4.id] }
             }
      end

      it "adds all members" do
        expect { action }.to change(Member, :count).by(3)
        expect(response).to redirect_to "/projects/pet_project/members?status=all"
        expect(user2).to be_member_of(project)
        expect(user3).to be_member_of(project)
        expect(user4).to be_member_of(project)
      end
    end

    context "with yet-to-be-invited emails" do
      let(:emails) { ["h.wurst@openproject.com", "1277551@openproject.com"] }
      let(:params) do
        {
          project_id: project.id,
          member: {
            role_ids: [role.id],
            user_ids: [emails.first] + [user2.id, user3.id] + [emails.last]
          }
        }
      end

      let(:invited_users) { User.where(mail: emails).to_a }
      let(:users) { invited_users + [user2, user3] }
      let(:original_member_count) { Member.count }

      before do
        original_member_count

        perform_enqueued_jobs do
          post :create, params:
        end
      end

      it "redirects to the members list" do
        expect(response).to redirect_to "/projects/pet_project/members?status=all"
      end

      it "adds members" do
        expect(users.size).to eq 4 # 2 emails, 2 existing users
        expect(users).to all be_member_of(project)

        expect(Member.count).to eq (original_member_count + users.size)
      end

      it "invites new users" do
        mails = ActionMailer::Base.deliveries

        expect(invited_users.size).to eq 2
        expect(mails.size).to eq invited_users.size
        expect(mails.map(&:to).flatten).to eq invited_users.map(&:mail)

        mails.each do |mail|
          expect(mail.subject).to include "account activation"
        end
      end
    end

    context "with a failed save" do
      let(:invalid_params) do
        { project_id: project.id,
          member: { role_ids: [],
                    user_ids: [user2.id, user3.id, user4.id] } }
      end

      before do
        post :create, params: invalid_params
      end

      it "does not redirect to the members index" do
        expect(response).not_to redirect_to "/projects/pet_project/members"
      end

      it "shows an error message" do
        expect(response.body).to include "Roles need to be assigned."
      end
    end
  end

  describe "#destroy_by_principal" do
    let(:action) do
      delete :destroy_by_principal, params: { project_id: project.id, principal_id: user.id, **more_params }
    end

    let(:role) { create(:project_role, permissions: %i[manage_members share_work_packages]) }
    let!(:project_role_member) do
      create(:member, project:,
                      user:,
                      roles: [role])
    end

    let(:work_package_role) { create(:view_work_package_role) }
    let!(:work_packages_shares) do
      Array.new(2) do
        create(:member,
               project:,
               roles: [work_package_role],
               entity: create(:work_package, project:),
               principal: user)
      end
    end

    before do
      allow(User).to receive(:current).and_return(user)
    end

    context "when requested to delete only project role member" do
      let(:more_params) { { project: "✓" } }

      it "destroys the project role member" do
        expect { action }.to change(Member, :count).by(-1)
        expect(response).to redirect_to "/projects/pet_project/members"
        expect(user).not_to be_member_of(project)
      end
    end

    context "when requested to delete only work packages shares" do
      let(:more_params) { { work_package_shares_role_id: "all" } }

      it "destroys the project role member" do
        expect { action }.to change(Member, :count).by(-2)
        expect(response).to redirect_to "/projects/pet_project/members"
        expect(user).to be_member_of(project)
      end
    end

    context "when requested to delete both project role member and work packages shares" do
      let(:more_params) { { project: "✓", work_package_shares_role_id: "all" } }

      it "destroys the project role member" do
        expect { action }.to change(Member, :count).by(-3)
        expect(response).to redirect_to "/projects/pet_project/members"
        expect(user).not_to be_member_of(project)
      end
    end
  end

  describe "#update" do
    let(:action) do
      post :update,
           params: {
             id: member.id,
             member: { role_ids: [role2.id], user_id: user.id }
           }
    end
    let(:role2) { create(:project_role) }

    before do
      member
    end

    it "updates the member" do
      expect { action }.not_to change(Member, :count)
      expect(response).to redirect_to "/projects/pet_project/members"
    end
  end
end
