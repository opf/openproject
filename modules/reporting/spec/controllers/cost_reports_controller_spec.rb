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

require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")

RSpec.describe CostReportsController do
  include OpenProject::Reporting::PluginSpecHelper

  let(:user) { build(:user) }
  let(:project) { build(:valid_project) }

  before do
    allow(User).to receive(:current).and_return(user)
  end

  describe "GET show" do
    before do
      is_member project, user, [:view_cost_entries]
    end

    context "with invalid units" do
      context "with :view_cost_entries permission" do
        before do
          get :show, params: { id: 1, unit: -1 }
        end

        it "returns 404 Not found" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "DELETE destroy" do
    let(:user) { build(:admin) }
    let(:cost_query) { create(:public_cost_query, user:, project:) }

    context "with valid params" do
      before do
        delete :destroy, params: { id: cost_query.id, project_id: project.identifier }
      end

      it "destroyed" do
        expect(CostQuery.count).to be_zero
      end

      it "redirected" do
        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid params" do
      before do
        create(:public_cost_query, user:, project:)
        delete :destroy, params: { id: -1, project_id: -1 }
      end

      it "not destroyed" do
        expect(CostQuery.count).not_to be_zero
      end

      it "returns 404 Not found" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with non-admin user" do
      let(:user) { build(:user) }

      before do
        delete :destroy, params: { id: cost_query.id, project_id: project.identifier }
      end

      it "not destroyed" do
        expect(CostQuery.count).not_to be_zero
      end

      it "returns 403 Forbidden" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
