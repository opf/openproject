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

RSpec.describe "Placeholder user matching users tab",
               type: :rails_request,
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

  context "for a placeholder user with criteria" do
    before { get edit_placeholder_user_path(with_criteria, tab: :matching_users) }

    it "renders the tab" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t(:label_matching_users))
    end

    it "lists the users the criteria select" do
      expect(response.body).to include("Eloper")
      expect(response.body).not_to include("Sales")
    end

    it "shows the criteria the list is based on" do
      expect(response.body).to include(Queries::FilterSummary.new(with_criteria.user_filter).to_s)
    end
  end

  context "for a placeholder user without criteria" do
    it "does not offer the tab" do
      get edit_placeholder_user_path(without_criteria, tab: :general)

      expect(response.body).not_to include(I18n.t(:label_matching_users))
    end
  end
end
