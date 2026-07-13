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

RSpec.describe Backlogs::BacklogController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }
  shared_let(:inbox_work_package) { create(:work_package, project:, status:) }
  shared_let(:bucket_work_package) { create(:work_package, project:, status:, backlog_bucket:) }
  shared_let(:sprint_work_package) { create(:work_package, project:, status:, sprint:) }

  current_user { user }

  describe "GET #show" do
    it "loads the backlog page and preserves the backlog menu item", :aggregate_failures do
      get :show, params: { project_id: project.id }, format: :html

      expect(response).to be_successful
      expect(response).to render_template("backlogs/backlog/show")
      expect(assigns(:project)).to eq(project)
      expect(controller.controller_path).to eq("backlogs/backlog")
      expect(controller.action_name).to eq("show")
      expect(controller.current_menu_item).to eq(:backlog)
    end

    context "for turbo frame request with frame id backlogs_container" do
      it "renders the backlog_list partial without layout", :aggregate_failures do
        request.headers["Turbo-Frame"] = "backlogs_container"
        get :show, params: { project_id: project.id }, format: :html

        expect(response).to be_successful
        expect(response).to render_template("backlogs/backlog/_backlog_list")
        expect(response).to render_template(layout: false)
        expect(assigns(:project)).to eq(project)
        expect(assigns(:backlog_buckets)).to match [backlog_bucket]
        expect(assigns(:sprints)).to match [sprint]
        expect(assigns(:work_packages_by_sprint_id)).to eq({ sprint.id => [sprint_work_package] })
        expect(assigns(:work_packages_by_backlog_id)).to eq({ nil => [inbox_work_package],
                                                              backlog_bucket.id => [bucket_work_package] })
      end
    end
  end
end
