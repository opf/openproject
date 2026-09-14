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

require_relative "../spec_helper"

RSpec.describe TimeEntriesController do
  include Redmine::I18n
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  let!(:project1) { create(:project) }
  let!(:work_package1) { create(:work_package, project: project1) }
  let!(:work_package2) { create(:work_package, project: project1) }

  let(:project2) { create(:project) }
  let(:work_package3) { create(:work_package, project: project2) }
  let(:work_package4) { create(:work_package, project: project2) }

  before do
    login_as user
  end

  describe "#dialog" do
    describe "authorization checks" do
      context "when opening dialog on an existing time entry" do
        let!(:time_entry1) { create(:time_entry, user: user, entity: work_package1) }
        let!(:time_entry2) { create(:time_entry, user: other_user, entity: work_package1) }

        context "and the user has the edit_own_time_entries permission on the work package" do
          before do
            role = create(:work_package_role, permissions: %i[view_own_time_entries edit_own_time_entries])
            create(:work_package_member, user: user, entity: work_package1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { id: time_entry1.id }, format: :turbo_stream
            expect(response).to be_successful
            expect(assigns(:time_entry)).to eq time_entry1
          end

          it "does not allow opening the dialog when the time entry belongs to another user" do
            get :dialog, params: { id: time_entry2.id }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has the edit_own_time_entries permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_own_time_entries edit_own_time_entries])
            user.members.find_by(project: project1).roles << role
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { id: time_entry1.id }, format: :turbo_stream
            expect(response).to be_successful
            expect(assigns(:time_entry)).to eq time_entry1
          end

          it "does not allow opening the dialog when the time entry belongs to another user" do
            get :dialog, params: { id: time_entry2.id }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has the edit_time_entries permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_time_entries edit_time_entries])
            user.members.find_by(project: project1).roles << role
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { id: time_entry1.id }, format: :turbo_stream
            expect(response).to be_successful
            expect(assigns(:time_entry)).to eq time_entry1
          end

          it "allows opening the dialog when the time entry belongs to another user" do
            get :dialog, params: { id: time_entry2.id }, format: :turbo_stream
            expect(response).to be_successful
            expect(assigns(:time_entry)).to eq time_entry2
          end
        end

        context "and the user has no edit permissions" do
          it "renders a 404" do
            get :dialog, params: { id: time_entry1.id }, format: :turbo_stream

            expect(response).to be_not_found
          end
        end
      end

      context "when opening dialog on a project" do
        context "and the user has the log_own_time permission on a work package within the project" do
          before do
            role = create(:work_package_role, permissions: %i[log_own_time])
            create(:work_package_member, user: user, entity: work_package1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { project_id: project1 }, format: :turbo_stream
            expect(response).to be_successful

            time_entry = assigns(:time_entry)
            expect(time_entry).to be_new_record
            expect(time_entry.project).to eq(project1)
          end

          it "does not allow to open the dialog for another project" do
            get :dialog, params: { project_id: project2 }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has the log_own_time permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_project log_own_time])
            create(:member, user: user, project: project1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { project_id: project1 }, format: :turbo_stream
            expect(response).to be_successful

            time_entry = assigns(:time_entry)
            expect(time_entry).to be_new_record
            expect(time_entry.project).to eq(project1)
          end
        end

        context "and the user has the log_time permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_project log_time])
            create(:member, user: user, project: project1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { project_id: project1 }, format: :turbo_stream
            expect(response).to be_successful

            time_entry = assigns(:time_entry)
            expect(time_entry).to be_new_record
            expect(time_entry.project).to eq(project1)
          end
        end

        context "and the user has no log permissions, but can view the project" do
          before do
            role = create(:project_role, permissions: %i[view_project])
            create(:member, user: user, project: project1, roles: [role])
          end

          it "does not allow to open the dialog" do
            get :dialog, params: { project_id: project1 }, format: :turbo_stream
            expect(response).to be_forbidden
          end
        end
      end

      context "when opening a dialog on a work package" do
        context "and the user has the log_own_time permission on the work package" do
          before do
            role = create(:work_package_role, permissions: %i[view_work_packages log_own_time])
            create(:work_package_member, user: user, entity: work_package1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { work_package_id: work_package1.id }, format: :turbo_stream
            expect(response).to be_successful

            time_entry = assigns(:time_entry)
            expect(time_entry).to be_new_record
            expect(time_entry.project).to eq(project1)
            expect(time_entry.entity).to eq(work_package1)
          end

          it "does not allow to open the dialog for another work package" do
            get :dialog, params: { work_package_id: work_package2.id }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has the log_own_time permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_work_packages log_own_time])
            create(:member, user: user, project: project1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { work_package_id: work_package1.id }, format: :turbo_stream
            expect(response).to be_successful
          end

          it "does not allow to open the dialog for work package from another project" do
            get :dialog, params: { work_package_id: work_package3.id }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has the log_time permission on the project" do
          before do
            role = create(:project_role, permissions: %i[view_work_packages log_time])
            create(:member, user: user, project: project1, roles: [role])
          end

          it "allows the user to open the dialog" do
            get :dialog, params: { work_package_id: work_package1.id }, format: :turbo_stream
            expect(response).to be_successful
          end

          it "does not allow to open the dialog for work package from another project" do
            get :dialog, params: { work_package_id: work_package3.id }, format: :turbo_stream
            expect(response).to be_not_found
          end
        end

        context "and the user has no log permission but can view the work package" do
          before do
            role = create(:work_package_role, permissions: %i[view_work_packages])
            create(:work_package_member, user: user, entity: work_package1, roles: [role])
          end

          it "does not allow to open the dialog" do
            get :dialog, params: { work_package_id: work_package1.id }, format: :turbo_stream
            expect(response).to be_forbidden
          end
        end
      end
    end
  end

  describe "#user_tz_caption" do
    let(:user) { create(:admin) } # so we don't have to mock permissions'

    render_views

    context "when current user and other user have different timezones" do
      before do
        user.pref.time_zone = "Europe/Berlin"
        other_user.pref.time_zone = "Asia/Tokyo"
        other_user.save
      end

      it "returns a notice about the different timezone" do
        get :user_tz_caption, params: { user_id: other_user.id }, format: :turbo_stream
        expect(response.body).to include(
          "caption=\"#{I18n.t('notice_different_time_zones',
                              tz: friendly_timezone_name(other_user.time_zone))}\""
        )
      end
    end

    context "when current user and other user have the same timezone" do
      before do
        user.pref.time_zone = "Europe/Berlin"
        other_user.pref.time_zone = "Europe/Berlin"
        other_user.save
      end

      it "returns no notice" do
        get :user_tz_caption, params: { user_id: other_user.id }, format: :turbo_stream
        expect(response.body).to include("caption=\"\"")
      end
    end
  end

  describe "#update" do
    let(:user) { create(:admin) } # so we don't have to mock permissions'
    let!(:time_entry) { create(:time_entry, user: other_user, project: project1, entity: work_package1) }

    render_views

    def update_with_user_id(user_id)
      put :update,
          params: {
            id: time_entry.id,
            time_entry: {
              user_id:,
              show_user: "true",
              show_work_package: "true",
              hours: "1",
              spent_on: Time.zone.today.iso8601
            }
          },
          format: :turbo_stream
    end

    context "when the submitted user does not resolve to a record" do
      it "re-renders the form for a blank user_id" do
        update_with_user_id("")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("time_entry_user_id")
        expect(time_entry.reload.user).to eq(other_user)
      end

      it "re-renders the form for a non-existent user_id" do
        update_with_user_id(User.maximum(:id) + 1)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("time_entry_user_id")
        expect(time_entry.reload.user).to eq(other_user)
      end
    end
  end
end
