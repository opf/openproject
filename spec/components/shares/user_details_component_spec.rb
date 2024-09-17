# frozen_string_literal: true

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

RSpec.describe Shares::UserDetailsComponent, type: :component do
  subject { render_inline(described_class.new(share:, strategy:, invite_resent:)) }

  shared_let(:project)      { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:work_package_role) { create(:view_work_package_role) }
  shared_let(:project_role) { create(:project_role, name: "Cool role") }

  shared_let(:user_firstname) { "Richard" }
  shared_let(:user_lastname)  { "Hendricks" }
  shared_let(:group_name)     { "Cool group" }
  shared_let(:strategy) do
    SharingStrategies::WorkPackageStrategy.new(work_package, query_params: {})
  end

  let(:invite_resent) { false }

  before do
    allow(strategy).to receive(:manageable?).and_return(manageable)
  end

  def build_inherited_membership(group_membership:, user_membership:, role: work_package_role)
    create(:member_role,
           member: user_membership,
           role:,
           inherited_from: group_membership.member_roles.first.id)
  end

  describe "when not in manager mode" do
    let(:manageable) { false }

    describe "rendering for a user in a non-active state" do
      context "when the user is locked" do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :locked) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        it do
          subject

          expect(page)
            .to have_text("Richard Hendricks", normalize_ws: true)
        end
      end

      context "when the user is invited" do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :invited) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        context "and the invite has not been resent" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Invite sent.", normalize_ws: true)
          end
        end

        context "and the invite has been resent" do
          let(:invite_resent) { true }

          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Invite sent.", normalize_ws: true)
          end
        end
      end
    end

    describe "rendering for a group" do
      shared_let(:principal) { create(:group, name: group_name) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context "when it is a member in the project" do
        before do
          create(:member, project:, principal:, roles: [project_role])
        end

        it do
          subject

          expect(page)
            .to have_text("Cool group", normalize_ws: true)
        end
      end

      context "when it is not a member in the project" do
        it do
          subject

          expect(page)
            .to have_text("Cool group", normalize_ws: true)
        end
      end
    end

    describe "rendering for a user" do
      shared_let(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context "when the user is not part of a shared with group" do
        context "and the user is not a project member" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks", normalize_ws: true)
          end
        end

        context "and the user is a project member" do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks", normalize_ws: true)
          end
        end
      end

      context "when the user is part of a shared with group" do
        shared_let(:group) { create(:group, name: group_name, members: [principal]) }

        before do
          group_share = create(:work_package_member,
                               principal: group,
                               entity: work_package,
                               roles: [work_package_role])

          build_inherited_membership(group_membership: group_share, user_membership: share)
        end

        context "and the user is not a project member" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks", normalize_ws: true)
          end
        end

        context "and the user is a project member" do
          before do
            create(:member, project:, principal:, roles: [project_role])
          end

          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks", normalize_ws: true)
          end
        end
      end
    end
  end

  describe "when in manager mode" do
    let(:manageable) { true }

    describe "rendering for a user in a non-active state" do
      context "when the user is locked" do
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

      context "when the user is invited" do
        let!(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname, status: :invited) }
        let!(:share) do
          create(:work_package_member,
                 principal:,
                 entity: work_package,
                 roles: [work_package_role])
        end

        context "and the invite has not been resent" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Invite sent. Resend.", normalize_ws: true)
          end
        end

        context "and the invite has been resent" do
          let(:invite_resent) { true }

          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Invite has been resent", normalize_ws: true)
          end
        end
      end
    end

    describe "rendering for a group" do
      shared_let(:principal) { create(:group, name: group_name) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context "when it is a member in the project" do
        before do
          create(:member, project:, principal:, roles: [project_role])
        end

        it do
          subject

          expect(page)
            .to have_text("Cool group Group members might have additional privileges (as project members)", normalize_ws: true)
        end
      end

      context "when it is not a member in the project" do
        it do
          subject

          expect(page)
            .to have_text("Cool group Group (shared with all members)", normalize_ws: true)
        end
      end
    end

    describe "rendering for a user" do
      shared_let(:principal) { create(:user, firstname: user_firstname, lastname: user_lastname) }
      shared_let(:share) do
        create(:work_package_member,
               principal:,
               entity: work_package,
               roles: [work_package_role])
      end

      context "when the user is a project member" do
        shared_let(:user_membership) { create(:member, project:, principal:, roles: [project_role]) }

        context "and the user is not part of any group" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Might have additional privileges (as project member)", normalize_ws: true)
          end
        end

        context "and the user is part of a group" do
          shared_let(:group) { create(:group, name: group_name, members: [principal]) }

          context "and the group is a project member itself" do
            before do
              group_membership = create(:member,
                                        project:,
                                        principal: group,
                                        roles: [project_role])

              build_inherited_membership(group_membership:, user_membership:, role: project_role)
            end

            context "and the group is shared with" do
              before do
                group_share = create(:work_package_member,
                                     principal: group,
                                     entity: work_package,
                                     roles: [work_package_role])

                build_inherited_membership(group_membership: group_share, user_membership: share)
              end

              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project or group member)",
                                normalize_ws: true)
              end
            end

            context "and the group is not shared with" do
              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project or group member)",
                                normalize_ws: true)
              end
            end
          end

          context "and the group is not a project member itself" do
            context "and the group is shared with" do
              before do
                group_share = create(:work_package_member,
                                     principal: group,
                                     entity: work_package,
                                     roles: [work_package_role])

                build_inherited_membership(group_membership: group_share, user_membership: share)
              end

              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project or group member)",
                                normalize_ws: true)
              end
            end

            context "and the group is not shared with" do
              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project member)",
                                normalize_ws: true)
              end
            end
          end
        end
      end

      context "when the user is not a project member" do
        context "and the user is not part of any group" do
          it do
            subject

            expect(page)
              .to have_text("Richard Hendricks Not a project member", normalize_ws: true)
          end
        end

        context "and the user is part of a group" do
          shared_let(:group) { create(:group, name: group_name, members: [principal]) }

          context "and the group is a project member itself" do
            before do
              group_membership = create(:member, project:, principal: group, roles: [project_role])
              user_membership = create(:member, project:, principal:, roles: [project_role])

              build_inherited_membership(group_membership:, user_membership:, role: project_role)
            end

            context "and the group is shared with" do
              before do
                group_share = create(:work_package_member,
                                     principal: group,
                                     entity: work_package,
                                     roles: [work_package_role])

                build_inherited_membership(group_membership: group_share, user_membership: share)
              end

              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project or group member)",
                                normalize_ws: true)
              end
            end

            context "and the group is not shared with" do
              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as project or group member)",
                                normalize_ws: true)
              end
            end
          end

          context "and the group is not a project member itself" do
            context "and the group is shared with" do
              before do
                group_share = create(:work_package_member,
                                     principal: group,
                                     entity: work_package,
                                     roles: [work_package_role])

                build_inherited_membership(group_membership: group_share, user_membership: share)
              end

              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Might have additional privileges (as group member)",
                                normalize_ws: true)
              end
            end

            context "and the group is not shared with" do
              it do
                subject

                expect(page)
                  .to have_text("Richard Hendricks Not a project member", normalize_ws: true)
              end
            end
          end
        end
      end
    end
  end
end
