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

require "rails_helper"

RSpec.describe Backlogs::WorkPackages::CardsController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:project) { create(:project, types: [type_feature]) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }
  shared_let(:work_package) do
    create(:work_package, subject: "A card", project:, type: type_feature, status:, story_points: 5)
  end

  current_user { user }

  describe "GET #show" do
    let(:params) { { project_id: project.id, work_package_id: work_package.id } }

    subject(:request) { get :show, params:, format: :html }

    context "with a user allowed to view the backlog" do
      shared_let(:user) { create(:admin) }

      it "renders the work package card inside its turbo-frame", :aggregate_failures do
        request

        expect(response).to have_http_status(:ok)
        expect(response.body).to have_css("turbo-frame#work_package_#{work_package.id}_card")
        expect(response.body).to have_text("A card")
        expect(response.body).to have_css(".sr-only", text: "5 story points")
      end

      it "marks the response as privately cacheable for a day" do
        request

        expect(response.headers["Cache-Control"]).to include("max-age=#{1.day.to_i}", "private")
      end

      context "when the work package is not in the requested project" do
        let(:other_project) { create(:project) }
        let(:params) { { project_id: other_project.id, work_package_id: work_package.id } }

        it { is_expected.to have_http_status(:not_found) }
      end
    end

    context "with a member lacking the permission" do
      shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

      it { is_expected.to have_http_status(:forbidden) }
    end
  end
end
