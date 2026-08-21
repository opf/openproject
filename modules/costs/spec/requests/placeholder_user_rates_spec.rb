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
      expect(response.body).to include("user-rate-history-list")
    end

    it "lists the projects the placeholder is a member of" do
      get edit_placeholder_user_path(placeholder, tab: :rates)

      expect(response.body).to include(project.name)
    end
  end

  describe "default rates" do
    it "can be edited" do
      get edit_hourly_rate_path(placeholder)

      expect(response).to have_http_status(:ok)
    end

    it "can be set and returns to the placeholder's rates tab" do
      put hourly_rate_path(placeholder), params: {
        user: {
          new_rate_attributes: { "0" => { valid_from: "2026-01-01", rate: "95" } },
          existing_rate_attributes: {}
        }
      }

      expect(placeholder.reload.default_rate_at(Date.new(2026, 6, 1)).rate).to eq(95)
      expect(response).to redirect_to(edit_placeholder_user_path(placeholder, tab: :rates))
    end
  end

  describe "project rates" do
    it "can be edited" do
      get edit_projects_hourly_rate_path(project_id: project, id: placeholder)

      expect(response).to have_http_status(:ok)
    end

    it "can be set and takes precedence over the default rate" do
      put hourly_rate_path(placeholder), params: {
        user: {
          new_rate_attributes: { "0" => { valid_from: "2026-01-01", rate: "95" } },
          existing_rate_attributes: {}
        }
      }
      put projects_hourly_rate_path(project_id: project, id: placeholder), params: {
        user: {
          new_rate_attributes: { "0" => { valid_from: "2026-01-01", rate: "120" } },
          existing_rate_attributes: {}
        }
      }

      expect(placeholder.reload.rate_at(Date.new(2026, 6, 1), project).rate).to eq(120)
    end
  end

  describe "for a principal that cannot hold a rate" do
    shared_let(:group) { create(:group) }

    it "is not found" do
      get edit_hourly_rate_path(group)

      expect(response).to have_http_status(:not_found)
    end
  end
end
