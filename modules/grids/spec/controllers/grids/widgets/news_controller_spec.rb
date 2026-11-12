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

require "rails_helper"

RSpec.describe Grids::Widgets::NewsController do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_news] }) }
  current_user { user }

  describe "GET #show" do
    before do
      allow(Grids::Widgets::News)
        .to receive(:new)
        .and_return(widget_instance)
    end

    context "for root" do
      let(:widget_instance) { instance_double(Grids::Widgets::News, render_in: "content") }

      before do
        get :show
      end

      it "renders widget", :aggregate_failures do
        expect(response).to be_successful
        expect(response.body).to eq "content"
      end
    end

    context "with project" do
      let(:widget_instance) { instance_double(Grids::Widgets::News, render_in: "content") }

      before do
        get :show, params: { project_id: project }
      end

      it "renders widget", :aggregate_failures do
        expect(response).to be_successful
        expect(response.body).to eq "content"
      end
    end

    context "with project and news module disabled" do
      let(:widget_instance) { instance_double(Grids::Widgets::News, render_in: "") }

      before do
        project.enabled_module_names -= %w[news]
        get :show, params: { project_id: project }
      end

      it "renders nothing", :aggregate_failures do
        expect(response).to be_successful
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end
  end
end
