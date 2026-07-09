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
require "rack/test"

RSpec.describe "API v3 meeting agenda items by work package", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking meetings]) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:other_work_package) { create(:work_package, project:) }

  let(:permissions) { %i[view_work_packages view_meetings] }
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:meeting) { create(:meeting, project:, author: current_user) }

  let!(:directly_linked_item) do
    create(:wp_meeting_agenda_item, meeting:, work_package:, author: current_user)
  end
  let!(:outcome_linked_item) do
    create(:meeting_agenda_item, meeting:, author: current_user).tap do |item|
      create(:meeting_outcome, meeting_agenda_item: item, kind: :work_package, work_package:, author: current_user)
    end
  end
  let!(:unrelated_item) do
    create(:wp_meeting_agenda_item, meeting:, work_package: other_work_package, author: current_user)
  end

  let(:path) { api_v3_paths.meeting_agenda_items_by_work_package(work_package.id) }
  let(:element_ids) { JSON.parse(last_response.body).dig("_embedded", "elements").pluck("id") }

  before do
    login_as current_user
    get path
  end

  subject(:response) { last_response }

  it "returns 200 with a collection" do
    expect(response).to have_http_status(:ok)

    expect(response.body)
      .to be_json_eql("Collection".to_json)
      .at_path("_type")
  end

  it "includes items linked directly and via outcomes, excluding unrelated items" do
    expect(element_ids).to contain_exactly(directly_linked_item.id, outcome_linked_item.id)
  end

  context "when an item is in a meeting the user cannot see" do
    let(:invisible_meeting) { create(:meeting, project: create(:project, enabled_module_names: %w[meetings])) }
    let!(:invisible_item) do
      create(:wp_meeting_agenda_item, meeting: invisible_meeting, work_package:)
    end

    it "excludes it from the collection" do
      expect(element_ids).not_to include(invisible_item.id)
    end
  end

  context "when a returned item links a work package the user cannot see through an outcome" do
    let(:inaccessible_work_package) { create(:work_package, project: create(:project)) }
    let!(:item_with_inaccessible_wp) do
      create(:wp_meeting_agenda_item, meeting:, work_package: inaccessible_work_package, author: current_user).tap do |item|
        create(:meeting_outcome, meeting_agenda_item: item, kind: :work_package, work_package:, author: current_user)
      end
    end

    before { get path }

    it "includes the item but discloses nothing about the inaccessible work package" do
      expect(element_ids).to include(item_with_inaccessible_wp.id)

      element = JSON.parse(last_response.body).dig("_embedded", "elements")
                    .find { |e| e["id"] == item_with_inaccessible_wp.id }

      expect(element.dig("_links", "workPackage", "href")).to eq(API::V3::URN_UNDISCLOSED)
      expect(element.dig("_embedded", "workPackage")).to be_nil

      expect(element["title"]).to be_nil
      expect(last_response.body).not_to include(inaccessible_work_package.subject)
    end
  end

  context "when no agenda items are linked to the work package" do
    let(:unlinked_work_package) { create(:work_package, project:) }
    let(:path) { api_v3_paths.meeting_agenda_items_by_work_package(unlinked_work_package.id) }

    it "returns an empty collection" do
      expect(response).to have_http_status(:ok)
      expect(element_ids).to be_empty
    end
  end

  context "without view_work_packages permission" do
    let(:permissions) { %i[view_meetings] }

    it "returns 404" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
