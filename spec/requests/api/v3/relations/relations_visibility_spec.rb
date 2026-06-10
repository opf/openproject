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

RSpec.describe "API v3 Relations visibility on relation filters", content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:project_visible) { create(:project, members: { user => role }) }
  let(:project_secret) { create(:project) }

  let(:visible_wp) { create(:work_package, project: project_visible, subject: "Visible task") }
  let(:secret_wp) { create(:work_package, project: project_secret, subject: "SECRET-ACQUISITION-PLAN-2026") }

  let!(:secret_to_visible) { create(:relation, from: secret_wp, to: visible_wp, relation_type: "relates") }
  let!(:visible_to_secret) { create(:relation, from: visible_wp, to: secret_wp, relation_type: "follows") }

  before do
    login_as user
  end

  def call_with_filter(filter_name, work_package_id)
    filter = [{ filter_name.to_sym => { operator: "=", values: [work_package_id.to_s] } }]

    get "#{api_v3_paths.relations}?filters=#{CGI::escape(JSON.dump(filter))}"
  end

  shared_examples "does not return invisible relations" do |filter_name|
    it "returns no relations to unavailable work packages" do
      call_with_filter(filter_name, secret_wp.id)

      body = JSON.parse(last_response.body)
      returned_relation_ids = Array(body.dig("_embedded", "elements")).pluck("id")

      expect(last_response).to have_http_status(:ok)
      expect(body["total"]).to eq(0)
      expect(body.dig("_embedded", "elements")).to eq([])
      expect(last_response.body).not_to include(secret_wp.subject)
      expect(returned_relation_ids).not_to include(secret_to_visible.id)
      expect(returned_relation_ids).not_to include(visible_to_secret.id)
    end
  end

  describe "GET /api/v3/relations with invisible work package filters" do
    include_examples "does not return invisible relations", "involved"
    include_examples "does not return invisible relations", "from"
    include_examples "does not return invisible relations", "to"
  end
end
