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

  describe "POST #create" do
    shared_let(:type) { create(:type_bug) }

    let(:project) { create(:project, types: []) }

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

  describe "DELETE #destroy" do
    shared_let(:type) { create(:type_bug) }

    let(:project) { create(:project, types: [type]) }

    it "reports a missing type rather than raising" do
      delete :destroy, params: { project_id: project.identifier, id: 0 }, format: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("The selected type could not be found.")
    end
  end
end
