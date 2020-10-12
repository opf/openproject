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

describe ::API::V3::Memberships::MembershipRepresenter, 'rendering' do
  include ::API::V3::Utilities::PathHelper

  let(:member) do
    FactoryBot.build_stubbed(:member,
                             member_roles: [member_role1, member_role2, member_role2, marked_member_role],
                             principal: principal,
                             project: project,
                             created_on: Time.current)
  end
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:roles) { [role1, role2] }
  let(:role1) { FactoryBot.build_stubbed(:role) }
  let(:member_role1) { FactoryBot.build_stubbed(:member_role, role: role1) }
  let(:role2) { FactoryBot.build_stubbed(:role) }
  let(:member_role2) { FactoryBot.build_stubbed(:member_role, role: role2) }
  let(:marked_role) { FactoryBot.build_stubbed(:role) }
  let(:marked_member_role) do
    FactoryBot.build_stubbed(:member_role, role: marked_role).tap do |mr|
      allow(mr)
        .to receive(:marked_for_destruction?)
        .and_return(true)
    end
  end
  let(:principal) { user }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:group) { FactoryBot.build_stubbed(:group) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:permissions) do
    [:manage_members]
  end
  let(:representer) do
    described_class.create(member, current_user: current_user, embed_links: true)
  end

  subject { representer.to_json }

  before do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, context_project|
      project == context_project && permissions.include?(permission)
    end
  end

  describe '_links' do
    describe 'self' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.membership member.id }
        let(:title) { user.name }
      end
    end

    describe 'schema' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'schema' }
        let(:href) { api_v3_paths.membership_schema }
      end
    end

    describe 'to update' do
      context 'if manage members permissions are granted' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'update' }
          let(:href) { api_v3_paths.membership_form(member.id) }
        end
      end

      describe 'if manage members permissions are lacking' do
        let(:permissions) { [] }

        it_behaves_like 'has no link' do
          let(:link) { 'update' }
        end
      end
    end

    describe 'to updateImmediately' do
      context 'if manage members permissions are granted' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'updateImmediately' }
          let(:href) { api_v3_paths.membership(member.id) }
        end
      end

      describe 'if manage members permissions are lacking' do
        let(:permissions) { [] }

        it_behaves_like 'has no link' do
          let(:link) { 'updateImmediately' }
        end
      end
    end

    describe 'project' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'project' }
        let(:href) { api_v3_paths.project(project.id) }
        let(:title) { project.name }
      end
    end

    describe 'principal' do
      context 'for a user principal' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'principal' }
          let(:href) { api_v3_paths.user(user.id) }
          let(:title) { user.name }
        end
      end

      context 'for a group principal' do
        let(:principal) { group }

        it_behaves_like 'has a titled link' do
          let(:link) { 'principal' }
          let(:href) { api_v3_paths.group(group.id) }
          let(:title) { group.name }
        end
      end
    end

    describe 'roles' do
      it_behaves_like 'has a link collection' do
        let(:link) { 'roles' }
        # excludes member_roles marked for destruction
        # and duplicates
        let(:hrefs) do
          [
            {
              href: api_v3_paths.role(role1.id),
              title: role1.name
            },
            {
              href: api_v3_paths.role(role2.id),
              title: role2.name
            }
          ]
        end
      end
    end
  end

  describe 'properties' do
    it_behaves_like 'property', :_type do
      let(:value) { 'Membership' }
    end

    it_behaves_like 'property', :id do
      let(:value) { member.id }
    end

    describe 'createdAt' do
      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { member.created_on }
        let(:json_path) { 'createdAt' }
      end
    end
  end

  describe '_embedded' do
    describe 'project' do
      let(:embedded_path) { '_embedded/project' }

      it 'has the project embedded' do
        is_expected
          .to be_json_eql('Project'.to_json)
          .at_path("#{embedded_path}/_type")

        is_expected
          .to be_json_eql(project.name.to_json)
          .at_path("#{embedded_path}/name")
      end
    end

    describe 'principal' do
      let(:embedded_path) { '_embedded/principal' }

      context 'for a user principal' do
        it 'has the user embedded' do
          is_expected
            .to be_json_eql('User'.to_json)
            .at_path("#{embedded_path}/_type")

          is_expected
            .to be_json_eql(user.name.to_json)
            .at_path("#{embedded_path}/name")
        end
      end

      context 'for a group principal' do
        let(:principal) { group }

        it 'has the group embedded' do
          is_expected
            .to be_json_eql('Group'.to_json)
            .at_path("#{embedded_path}/_type")

          is_expected
            .to be_json_eql(group.name.to_json)
            .at_path("#{embedded_path}/name")
        end
      end
    end

    describe 'roles' do
      let(:embedded_path) { '_embedded/roles' }

      it 'has an array of roles embedded that excludes member_roles marked for destruction' do
        is_expected
          .to be_json_eql('Role'.to_json)
          .at_path("#{embedded_path}/0/_type")

        is_expected
          .to be_json_eql(role1.name.to_json)
          .at_path("#{embedded_path}/0/name")

        is_expected
          .to be_json_eql('Role'.to_json)
          .at_path("#{embedded_path}/1/_type")

        is_expected
          .to be_json_eql(role2.name.to_json)
          .at_path("#{embedded_path}/1/name")
      end
    end
  end
end
