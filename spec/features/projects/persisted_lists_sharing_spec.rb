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

RSpec.describe "Project list sharing",
               :js,
               :with_cuprite do
  shared_let(:view_project_query_role) { create(:view_project_query_role) }
  shared_let(:edit_project_query_role) { create(:edit_project_query_role) }

  shared_let(:sharer) do
    create(:user,
           firstname: "Han",
           lastname: "Solo",
           member_with_permissions: { project_where_both_are_members => %i[view_work_packages edit_work_packages] })
  end
  shared_let(:shared_user) do
    create(:user,
           firstname: "Jabba",
           lastname: "The Hutt",
           member_with_permissions: { project_where_both_are_members => %i[view_work_packages edit_work_packages] })
  end
  shared_let(:wildcard_user) do
    create(:user,
           firstname: "Marty",
           lastname: "McFly",
           member_with_permissions: { project_where_both_are_members => %i[view_work_packages edit_work_packages] })
  end

  shared_let(:project_role) { create(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
  shared_let(:project_where_both_are_members) do
    create(:project,
           name: "Shared project",
           identifier: "shared-project") do |project|
      create(:member, project:, user: sharer, roles: [project_role])
      create(:member, project:, user: shared_user, roles: [project_role])
      create(:member, project:, user: wildcard_user, roles: [project_role])
    end
  end

  shared_let(:shared_projects_list) do
    create(:project_query,
           name: "Member-of list",
           user: sharer,
           select: %w[name]) do |query|
      query.where("member_of", "=", OpenProject::Database::DB_VALUE_TRUE)
      query.save!
    end
  end

  let(:projects_index_page) { Pages::Projects::Index.new }
  let(:share_dialog) { Components::Sharing::ProjectQueries::ShareModal.new(shared_projects_list) }

  describe "without the enterprise edition" do
    it "renders an upsale modal" do
      login_as(sharer)

      projects_index_page.visit!
      projects_index_page.set_sidebar_filter "Member-of list"
      projects_index_page.open_share_dialog

      share_dialog.expect_open
      share_dialog.expect_upsale_banner
    end
  end

  describe "with the enterprise edition", with_ee: %i[project_list_sharing] do
    describe "Sharing with View permissions with a user " \
             "and accessing the list as the shared user" do
      it "allows the shared user to view the project list but not edit it" do
        using_session "shared user" do
          login_as(shared_user)

          projects_index_page.visit!
          projects_index_page.expect_no_sidebar_filter("Member-of list")
        end

        using_session "sharer" do
          login_as(sharer)

          projects_index_page.visit!
          projects_index_page.set_sidebar_filter "Member-of list"
          projects_index_page.open_share_dialog

          share_dialog.expect_open
          share_dialog.invite_user!(shared_user, "View")
        end

        using_session "shared user" do
          login_as(shared_user)
          projects_index_page.visit!
          projects_index_page.expect_sidebar_filter("Member-of list")
          projects_index_page.set_sidebar_filter("Member-of list")
          projects_index_page.open_share_dialog

          share_dialog.expect_unable_to_manage
          share_dialog.close

          projects_index_page.open_filters
          projects_index_page.filter_by_active("yes")

          wait_for_reload

          projects_index_page.expect_can_only_save_as_label
          projects_index_page.save_query_as("Member-of and active list")

          wait_for_network_idle

          projects_index_page.expect_sidebar_filter("Member-of and active list", selected: true)
        end
      end
    end

    describe "Sharing with Edit permissions with a user " \
             "and accessing the list as the shared user" do
      it "allows the shared user to view, share and edit the project list" do
        using_session "shared user" do
          login_as(shared_user)

          projects_index_page.visit!
          projects_index_page.expect_no_sidebar_filter("Member-of list")
        end

        using_session "sharer" do
          login_as(sharer)

          projects_index_page.visit!
          projects_index_page.set_sidebar_filter "Member-of list"
          projects_index_page.open_share_dialog

          share_dialog.expect_open
          share_dialog.invite_user!(shared_user, "Edit")
        end

        using_session "shared user" do
          login_as(shared_user)
          projects_index_page.visit!
          projects_index_page.expect_sidebar_filter("Member-of list")
          projects_index_page.set_sidebar_filter("Member-of list")
          projects_index_page.open_share_dialog

          share_dialog.expect_open
          # Allowed to further share the project list
          share_dialog.invite_user!(wildcard_user, "View")
          share_dialog.close

          projects_index_page.open_filters
          projects_index_page.filter_by_active("yes")

          # Can save the project list
          projects_index_page.save_query
          # TODO: Toast is currently not rendered in turbo actions
          # projects_index_page.expect_toast(message: "The modified list has been saved")
        end
      end
    end

    context "without the permission to manage public project lists" do
      it "doesn't allow making a list public" do
        login_as(sharer)

        projects_index_page.visit!
        projects_index_page.set_sidebar_filter "Member-of list"
        projects_index_page.open_share_dialog

        share_dialog.expect_open
        share_dialog.expect_toggle_public_disabled
      end

      context "and the list is already public" do
        before do
          shared_projects_list.update(public: OpenProject::Database::DB_VALUE_TRUE)
        end

        it "doesn't allow the owner to edit its public state" do
          login_as(sharer)

          projects_index_page.visit!
          projects_index_page.set_sidebar_filter "Member-of list"
          projects_index_page.open_share_dialog

          share_dialog.expect_open
          share_dialog.expect_toggle_public_disabled
        end
      end
    end

    describe "Making a list public" do
      shared_let(:global_member) do
        create(:global_member,
               principal: sharer,
               roles: [create(:global_role, permissions: %i[manage_public_project_queries])])
      end

      context "and accessing it as a user without edit permissions" do
        it "allows the user to view the list" do
          using_session "shared user" do
            login_as(shared_user)

            projects_index_page.visit!
            projects_index_page.expect_no_sidebar_filter("Member-of list")
          end

          using_session "sharer" do
            login_as(sharer)

            projects_index_page.visit!
            projects_index_page.set_sidebar_filter "Member-of list"
            projects_index_page.open_share_dialog

            share_dialog.expect_open
            share_dialog.toggle_public
            share_dialog.close
          end

          using_session "shared user" do
            login_as(shared_user)
            projects_index_page.visit!
            projects_index_page.expect_sidebar_filter("Member-of list")
            projects_index_page.set_sidebar_filter("Member-of list")
            projects_index_page.open_share_dialog

            # View only
            share_dialog.expect_unable_to_manage(only_invite: true)
            share_dialog.close

            projects_index_page.open_filters
            projects_index_page.filter_by_active("yes")
            projects_index_page.expect_can_only_save_as_label
            projects_index_page.save_query_as("Member-of and active list")

            wait_for_network_idle

            projects_index_page.expect_sidebar_filter("Member-of and active list", selected: true)
          end
        end
      end

      context "and sharing it with a user with edit permissions" do
        it "allows the user to view, share and edit the list" do
          using_session "shared user" do
            login_as(shared_user)

            projects_index_page.visit!
            projects_index_page.expect_no_sidebar_filter("Member-of list")
          end
          using_session "sharer" do
            login_as(sharer)

            projects_index_page.visit!
            projects_index_page.set_sidebar_filter "Member-of list"
            projects_index_page.open_share_dialog

            share_dialog.expect_open
            share_dialog.toggle_public
            share_dialog.invite_user!(shared_user, "Edit")
            share_dialog.close
          end

          using_session "shared user" do
            login_as(shared_user)
            projects_index_page.visit!
            projects_index_page.expect_sidebar_filter("Member-of list")
            projects_index_page.set_sidebar_filter("Member-of list")
            projects_index_page.open_share_dialog

            # Allowed to further share the project list
            share_dialog.invite_user!(wildcard_user, "View")
            share_dialog.close

            projects_index_page.open_filters
            projects_index_page.filter_by_active("yes")

            # Can save the project list
            projects_index_page.save_query
            # TODO: Toast is currently not rendered in turbo actions
            # projects_index_page.expect_toast(message: "The modified list has been saved")
          end
        end
      end
    end
  end
end
