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

RSpec.describe Backlogs::BurndownChartController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }
  shared_let(:sprint) { create(:sprint, project:) }

  current_user { user }

  describe "GET #show" do
    it "renders under the namespaced controller runtime", :aggregate_failures do
      get :show, params: { project_id: project.id, sprint_id: sprint.id }, format: :html

      expect(response).to be_successful
      expect(response).to render_template("backlogs/burndown_chart/show")
      expect(controller.controller_path).to eq("backlogs/burndown_chart")
      expect(assigns(:project)).to eq(project)
      expect(assigns(:sprint)).to eq(sprint)
    end
  end
end
