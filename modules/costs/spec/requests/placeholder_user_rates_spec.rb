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

require_relative "../spec_helper"

RSpec.describe "Placeholder user rates",
               :skip_csrf,
               type: :rails_request,
               with_ee: %i[placeholder_users] do
  shared_let(:placeholder) { create(:placeholder_user, name: "Senior Developer") }
  shared_let(:project) { create(:project) }

  shared_let(:membership) do
    create(:member, principal: placeholder, project:, roles: [create(:project_role)])
  end

  current_user { create(:admin) }

  describe "the rates tab" do
    it "is rendered for a placeholder user" do
      get edit_placeholder_user_path(placeholder, tab: :rates)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(User.human_attribute_name(:default_rates))
    end

    it "lists the projects the placeholder is a member of" do
      get edit_placeholder_user_path(placeholder, tab: :rates)

      expect(response.body).to include(project.name)
    end

    it "shows the rate history of a project the placeholder has a rate in" do
      create(:hourly_rate, principal: placeholder, project:, valid_from: Date.current, rate: 95)

      get edit_placeholder_user_path(placeholder, tab: :rates)

      expect(response.body).to include("95.00")
    end
  end

  describe "the project rate history" do
    it "renders a blank slate when the placeholder has no rate in the project" do
      get projects_hourly_rate_path(project_id: project, id: placeholder)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t(:no_results_title_text))
    end

    context "with a rate history" do
      before do
        create(:hourly_rate, principal: placeholder, project:, valid_from: 1.year.ago, rate: 80)
        create(:hourly_rate, principal: placeholder, project:, valid_from: Date.current, rate: 95)

        get projects_hourly_rate_path(project_id: project, id: placeholder)
      end

      it "names the project and the rate in effect in the header" do
        expect(response.body).to include(project.name)
        expect(response.body).to include(Rate.human_attribute_name(:current_rate))
        expect(response.body).to include("95.00")
      end

      it "lists every rate of the history" do
        expect(response.body).to include("80.00")
        expect(response.body).to include("95.00")
      end
    end
  end

  describe "for a principal that cannot hold a rate" do
    shared_let(:group) { create(:group, member_with_roles: { project => create(:project_role) }) }

    it "is not found" do
      get projects_hourly_rate_path(project_id: project, id: group)

      expect(response).to have_http_status(:not_found)
    end
  end
end
