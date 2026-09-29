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

RSpec.describe Projects::Settings::WorkPackages::TypesController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  describe "PATCH #bulk_update" do
    let(:type) { create(:type_bug) }
    let(:other_type) { create(:type_task) }
    let(:project) { create(:project, types: [type, other_type]) }
    let!(:work_package) { create(:work_package, project:, type:) }

    before do
      patch :bulk_update,
            params: {
              project_id: project.identifier,
              project: { type_ids: [other_type.id.to_s] }
            }
    end

    it { expect(response).to redirect_to(project_settings_types_path(project.identifier)) }

    it "shows an error message with a link to the affected work packages" do
      refusal = %(Unable to remove "#{type.name}" from project "#{project.name}" \
because it's still in use by work packages)

      expect(sanitize_string(flash[:error].first)).to include(refusal)
      expect(flash[:error].first)
        .to include(work_packages_path(query_props: { f: [
          { n: "type", o: "=", v: [type.id] },
          { n: "project", o: "=", v: [project.id.to_s] }
        ] }.to_json))
    end

    it "keeps the type active in the project" do
      expect(project.enabled_types).to include(type)
    end
  end

  describe "POST #create" do
    shared_let(:type) { create(:type_bug) }

    let(:project) { create(:project, types: []) }

    context "with the type variants feature active", with_flag: { type_variants: true } do
      it "reports a missing type rather than raising" do
        post :create, params: { project_id: project.identifier }, format: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("The selected type could not be found.")
      end

      it "activates the type" do
        post :create, params: { project_id: project.identifier, variant_id: type.default_variant.id }, format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(project.enabled_types).to include(type)
      end
    end

    context "with the type variants feature inactive", with_flag: { type_variants: false } do
      it "renders 404" do
        post :create, params: { project_id: project.identifier, type_id: type.id }, format: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy", with_flag: { type_variants: true } do
    shared_let(:type) { create(:type_bug) }

    let(:project) { create(:project, types: [type]) }

    it "reports a missing type rather than raising" do
      delete :destroy, params: { project_id: project.identifier, id: 0 }, format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("The selected type could not be found.")
    end
  end
end
