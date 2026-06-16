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

RSpec.describe "Work package activities tab",
               :aggregate_failures,
               type: :rails_request,
               with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, author: user) }

  # Created per-example so the no-aggregation setting applies; under shared_let it
  # would be built in before_all at default settings and merged into the initial journal.
  let!(:comment) do
    create(:work_package_journal, user:, notes: "A comment", journable: work_package, version: 2)
  end

  # The data attribute the client reads to scroll a resolved activity anchor.
  let(:resolved_value_attribute) { "work-packages--activities-tab--auto-scrolling-resolved-comment-id-value" }

  before { login_as(user) }

  # The frontend converts the legacy #activity-N URL fragment into an ?anchor=
  # query param before requesting the tab, so the anchor arrives as a query param.
  describe "GET index" do
    it "exposes the resolved comment id for a legacy activity anchor" do
      # activity-2 is the journal with sequence_version 2, i.e. the comment
      get work_package_activities_path(work_package), params: { anchor: "activity-2" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(#{resolved_value_attribute}="#{comment.id}"))
    end

    it "omits the resolved-comment value without an activity anchor" do
      get work_package_activities_path(work_package)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(resolved_value_attribute)
    end

    it "omits the resolved-comment value for a comment anchor" do
      get work_package_activities_path(work_package), params: { anchor: "comment-#{comment.id}" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(resolved_value_attribute)
    end

    it "omits the resolved-comment value for an unresolvable activity anchor" do
      get work_package_activities_path(work_package), params: { anchor: "activity-999999" }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(resolved_value_attribute)
    end
  end
end
