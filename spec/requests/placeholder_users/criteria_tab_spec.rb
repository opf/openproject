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

RSpec.describe "Placeholder user filter criteria tab",
               :skip_csrf, type: :rails_request,
                           with_ee: %i[placeholder_users] do
  shared_let(:matching_user) { create(:user, firstname: "Dev", lastname: "Eloper") }
  shared_let(:other_user) { create(:user, firstname: "Sales", lastname: "Person") }

  shared_let(:with_criteria) do
    query = UserQuery.new
    query.where("name", "~", ["Eloper"])
    create(:placeholder_user, name: "Senior Developer", user_filter: query.filters)
  end

  shared_let(:without_criteria) { create(:placeholder_user, name: "Just a seat") }

  current_user { create(:admin) }

  describe "with criteria" do
    shared_let(:department) { create(:group, organizational_unit: true, name: "Titan Team", members: [matching_user]) }
    shared_let(:job_title) do
      create(:user_custom_field, :string, name: "Position", semantic_key: :job_title).tap do |field|
        matching_user.custom_values.create!(custom_field: field, value: "Frontend Developer")
      end
    end

    before { get edit_placeholder_user_path(with_criteria, tab: :criteria) }

    it "offers the criteria builder next to the users meeting them" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("placeholder_users.criteria.activate"))
      expect(response.body).to include("op-filters-form")
      expect(response.body).to include(I18n.t("placeholder_users.criteria.matching_users"))
    end

    it "lists the users the criteria select" do
      expect(response.body).to include("Eloper")
      expect(response.body).not_to include("Sales")
    end

    it "names each user's department and job title where they are known" do
      expect(response.body).to include("Titan Team")
      expect(response.body).to include("Frontend Developer")
    end
  end

  describe "without criteria" do
    before { get edit_placeholder_user_path(without_criteria, tab: :criteria) }

    it "offers only the toggle" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("placeholder_users.criteria.activate"))
      expect(response.body).not_to include("op-filters-form")
      expect(response.body).not_to include(I18n.t("placeholder_users.criteria.matching_users"))
    end
  end

  describe "GET update_criteria" do
    it "stores the edited criteria and lists the users they select" do
      get update_criteria_placeholder_user_path(
        without_criteria,
        filters: [{ name: { operator: "~", values: ["Eloper"] } }].to_json
      ), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response).to have_turbo_stream(
        action: "update",
        target: PlaceholderUsers::MatchingUsersComponent.wrapper_key
      )
      expect(response.body).to include("Eloper")
      expect(response.body).not_to include("Sales")

      expect(without_criteria.reload.user_filter.first.values).to eq(["Eloper"])
    end

    it "stores an emptied criteria set" do
      get update_criteria_placeholder_user_path(with_criteria, filters: [].to_json), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(with_criteria.reload.user_filter).to be_empty
    end
  end

  describe "POST toggle_criteria" do
    it "drops the criteria when switched off and re-renders the tab" do
      post toggle_criteria_placeholder_user_path(with_criteria, value: "0"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(with_criteria.reload.user_filter).to be_empty
      expect(response).to have_turbo_stream(
        action: "update",
        target: PlaceholderUsers::CriteriaComponent.wrapper_key
      )
      expect(response.body).not_to include("op-filters-form")
    end

    it "opens the builder when switched on, keeping the stored criteria" do
      post toggle_criteria_placeholder_user_path(with_criteria, value: "1"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(with_criteria.reload.user_filter).not_to be_empty
      expect(response.body).to include("op-filters-form")
    end

    it "opens an empty builder when switched on for a placeholder without criteria" do
      post toggle_criteria_placeholder_user_path(without_criteria, value: "1"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("op-filters-form")
    end

    it "is denied without the permission to manage placeholder users" do
      login_as create(:user)

      post toggle_criteria_placeholder_user_path(with_criteria, value: "0")

      expect(response).to have_http_status(:forbidden)
    end
  end
end
