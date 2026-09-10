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

RSpec.describe Backlogs::FiltersController do
  shared_let(:project) { create(:project) }

  let(:all_permissions) { %i[view_sprints view_work_packages show_board_views] }
  let(:permissions) { all_permissions }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  describe "GET #show" do
    let(:params) { {} }

    subject do
      get :show, params: { project_id: project.id }.merge(params), format: :html
    end

    it "renders the filters panel without layout", :aggregate_failures do
      subject

      expect(response).to be_successful
      expect(response).to render_template(layout: false)
    end

    context "with a filter active" do
      let(:status) { create(:status) }
      let(:params) { { filters: "status_id = \"#{status.id}\"" } }

      it "renders a generic attribute filter" do
        subject
        expect(response.body).to include("status_id")
      end
    end

    context "without the view_sprints permission" do
      let(:permissions) { all_permissions - [:view_sprints] }

      it "responds with forbidden", :aggregate_failures do
        subject

        expect(response).not_to be_successful
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
