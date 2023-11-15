# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
require 'spec_helper'

RSpec.describe WorkPackages::Share::UserDetailsComponent, type: :component do
  subject { render_inline(described_class.new(user: principal, share:, manager_mode:)) }

  shared_let(:project)      { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:work_package_role) { create(:view_work_package_role) }
  shared_let(:project_role) { create(:project_role, name: 'Cool role') }

  shared_let(:user_firstname) { 'Richard' }
  shared_let(:user_lastname)  { 'Hendricks' }
  shared_let(:group_name)     { 'Cool group' }

  def build_inherited_share(group_share:, user_share:)
    create(:member_role,
           member: user_share,
           role: work_package_role,
           inherited_from: group_share.member_roles.first.id)
  end

  describe 'when not in manager mode' do
    let(:manager_mode) { false }

    describe 'rendering for a user in a non-active state' do
      context 'when the user is locked' do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :locked) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Richard Hendricks Role: View", normalize_ws: true)
        end
      end

      context 'when the user is invited' do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :invited) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Richard Hendricks Pending invitation. Role: View", normalize_ws: true)
        end
      end
    end

    describe 'rendering for a group' do
      shared_let(:principal) { create(:group, name: group_name) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context 'when it is a member in the project' do
        before do
          create(:member, project:, principal:, roles: [project_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Cool group Role: View", normalize_ws: true)
        end
      end

      context 'when it is not a member in the project' do
        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Cool group Role: View", normalize_ws: true)
        end
      end
    end

    describe 'rendering for a user' do
      shared_let(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context 'when the user is not part of a shared with group' do
        context 'and the user is not a project member' do
          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Role: View", normalize_ws: true)
          end
        end

        context 'and the user is a project member' do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Role: View", normalize_ws: true)
          end
        end
      end

      context 'when the user is part of a shared with group' do
        shared_let(:group) { create(:group, name: group_name, members: [principal]) }

        before do
          group_share = create(:work_package_member,
                               principal: group,
                               entity: work_package,
                               roles: [work_package_role])

          build_inherited_share(group_share:, user_share: share)
        end

        context 'and the user is not a project member' do
          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Role: View", normalize_ws: true)
          end
        end

        context 'and the user is a project member' do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Role: View", normalize_ws: true)
          end
        end
      end
    end
  end

  describe 'when in manager mode' do
    let(:manager_mode) { true }

    describe 'rendering for a user in a non-active state' do
      context 'when the user is locked' do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :locked) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_css(".octicon-lock")
          expect(page)
            .to have_text("Richard Hendricks Locked user", normalize_ws: true)
        end
      end

      context 'when the user is invited' do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :invited) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Richard Hendricks Pending invitation. Resend invite", normalize_ws: true)
        end
      end
    end

    describe 'rendering for a group' do
      shared_let(:principal) { create(:group, name: group_name) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context 'when it is a member in the project' do
        before do
          create(:member, project:, principal:, roles: [project_role])
        end

        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Cool group Project group", normalize_ws: true)
        end
      end

      context 'when it is not a member in the project' do
        it "", :aggregate_failures do
          subject

          expect(page)
            .to have_text("Cool group Not project group", normalize_ws: true)
        end
      end
    end

    describe 'rendering for a user' do
      shared_let(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context 'when the user is not part of a shared with group' do
        context 'and the user is not a project member' do
          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Not project member", normalize_ws: true)
          end
        end

        context 'and the user is a project member' do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Project member: Cool role", normalize_ws: true)
          end
        end
      end

      context 'when the user is part of a shared with group' do
        shared_let(:group) { create(:group, name: group_name, members: [principal]) }

        before do
          group_share = create(:work_package_member,
                               principal: group,
                               entity: work_package,
                               roles: [work_package_role])

          build_inherited_share(group_share:, user_share: share)
        end

        context 'and the user is not a project member' do
          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Part of a shared group", normalize_ws: true)
          end
        end

        context 'and the user is a project member' do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it "", :aggregate_failures do
            subject

            expect(page)
              .to have_text("Richard Hendricks Part of a shared group. Project member: Cool role", normalize_ws: true)
          end
        end
      end
    end
  end
end
