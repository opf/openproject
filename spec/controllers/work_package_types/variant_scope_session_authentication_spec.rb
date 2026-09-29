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

# The user is established from the session here, deliberately, rather than through login_as or
# the current_user helper. Those stub RequestStore[:current_user] — the very thing
# ApplicationController#user_setup fills in — so they resolve User.current whether or not
# user_setup ran, and a controller authorizing ahead of it passes them while redirecting every
# real signed-in administrator to the login page.
RSpec.describe "Project-scoped variant screens for a session-authenticated user", # rubocop:disable RSpec/DescribeClass
               with_flag: { type_variants: true } do
  shared_let(:project) { create(:project) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:ours) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
  shared_let(:project_admin) do
    create(:user, member_with_permissions: { project => %i[manage_project_variants] })
  end

  before { session[:user_id] = project_admin.id }

  describe WorkPackageTypes::DetailsTabController do
    it "renders the tab rather than bouncing to the login page" do
      get :edit, params: { in_project_id: project.identifier, type_id: type.id, variant_id: ours.id }

      expect(response).to have_http_status(:ok)
    end

    it "still hides a variant the project does not own" do
      theirs = create(:project_owned_type_variant, type:, project: create(:project))

      get :edit, params: { in_project_id: project.identifier, type_id: type.id, variant_id: theirs.id }

      expect(response).to have_http_status(:not_found)
    end

    context "when the member may not manage the project's variants" do
      before { session[:user_id] = create(:user, member_with_permissions: { project => %i[view_project] }).id }

      it "is refused rather than served" do
        get :edit, params: { in_project_id: project.identifier, type_id: type.id, variant_id: ours.id }

        expect(response).not_to have_http_status(:ok)
      end
    end
  end

  describe WorkPackageTypes::CreationWizardController do
    it "opens the first step rather than bouncing to the login page" do
      get :new, params: { in_project_id: project.identifier, type_id: type.id }

      expect(response).to have_http_status(:ok)
    end
  end

  describe WorkPackageTypes::PdfExportTemplateController do
    it "renders the tab, whose template lookup follows the variant" do
      get :edit, params: { in_project_id: project.identifier, type_id: type.id, variant_id: ours.id }

      expect(response).to have_http_status(:ok)
    end
  end
end
