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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Projects::HoverCardController, type: :rails_request do
  shared_let(:project) { create(:project, public: false, name: "Visible project") }
  shared_let(:archived_project) { create(:project, active: false, public: false, name: "Archived project") }

  shared_let(:admin) { create(:admin) }
  shared_let(:member_with_permission) do
    create(:user, member_with_permissions: { project => %i[view_project] })
  end
  shared_let(:member_without_permission) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:archived_member) do
    create(:user, member_with_permissions: { archived_project => %i[view_project] })
  end
  shared_let(:non_member) { create(:user) }

  subject(:perform) { get hover_card_project_path(requested_id) }

  let(:requested_id) { project.id }

  before do
    login_as(current_user) if current_user
  end

  describe "GET show" do
    context "as an admin" do
      let(:current_user) { admin }

      it "renders the hover card" do
        perform

        expect(response).to have_http_status(:ok)
      end

      context "when the project does not exist" do
        let(:requested_id) { 0 }

        it "responds with 404" do
          perform

          expect(response).to have_http_status(:not_found)
        end
      end

      context "when the project is archived" do
        let(:requested_id) { archived_project.id }

        it "renders the hover card with the archived label", pending: "https://community.openproject.org/wp/DREAM-1005" do
          perform

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Archived project")
          expect(response.body).to include(I18n.t("project.archive.archived"))
        end
      end
    end

    context "as a member with :view_project" do
      let(:current_user) { member_with_permission }

      it "renders the hover card" do
        perform

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Visible project")
      end

      it "does not show the archived label" do
        perform

        expect(response.body).not_to include(I18n.t("project.archive.archived"))
      end

      context "when the project does not exist" do
        let(:requested_id) { 0 }

        it "responds with 404" do
          perform

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "as a non-member" do
      let(:current_user) { non_member }

      it "responds with 403" do
        perform

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as an anonymous user" do
      let(:current_user) { nil }

      it "redirects to the login page" do
        perform

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(signin_path(back_url: hover_card_project_url(requested_id)))
      end
    end

    context "when the project is archived and the user is a non-admin" do
      let(:requested_id) { archived_project.id }

      context "with the permission in the archived project" do
        let(:current_user) { archived_member }

        it "responds with 403" do
          perform

          expect(response).to have_http_status(:forbidden)
        end
      end

      context "as a non-member" do
        let(:current_user) { non_member }

        it "responds with 403" do
          perform

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
