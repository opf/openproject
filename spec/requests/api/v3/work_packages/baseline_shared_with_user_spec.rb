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

# Characterization of a known gap, not of intended behaviour.
#
# `shared_with_user` contributes nothing but "1=1" to Query#statement and applies itself in
# #apply_to, which reaches the query only through `filter_merges`. Query::Results merges those
# in its "today" branch alone, so at a baseline timestamp the filter matches every visible work
# package.
#
# The frontend derives every row's baseline badge from the two `_meta` flags asserted here
# (frontend/src/app/features/work-packages/components/wp-baseline/baseline-helpers.ts:92).
#
# When the gap is closed these expectations have to be inverted.
RSpec.describe "API v3 work packages baseline with a sharedWithUser filter",
               content_type: :json,
               with_ee: %i[baseline_comparison] do
  include API::V3::Utilities::PathHelper

  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) { create(:project) }
  shared_let(:work_package_role) { create(:view_work_package_role) }

  shared_let(:baseline_time) { Timestamp.parse("2015-01-01T00:00:00Z") }
  shared_let(:created_at) { baseline_time.to_time - 1.day }

  # A user outside every project the current user can see is not in
  # PrincipalBaseFilter#allowed_values, which makes the filter and with it the whole query
  # invalid. Query#statement then collapses to 1=0 and every expectation goes vacuous.
  shared_let(:sharer) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end

  shared_let(:shared_work_package) do
    create(:work_package,
           project:,
           subject: "Shared before the baseline",
           created_at:,
           journals: { created_at => {} }) do |wp|
      create(:member, user: sharer, project:, entity: wp, roles: [work_package_role])
    end
  end

  shared_let(:unrelated_work_package) do
    create(:work_package,
           project:,
           subject: "Never shared with anyone",
           created_at:,
           journals: { created_at => {} })
  end

  shared_let(:newly_shared_work_package) do
    create(:work_package,
           project:,
           subject: "Shared after the baseline",
           created_at:,
           journals: { created_at => {} }) do |wp|
      create(:member, user: sharer, project:, entity: wp, roles: [work_package_role])
    end
  end

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages view_shared_work_packages]
           })
  end

  subject(:api_response) do
    get path
    last_response
  end

  let(:filters) do
    [{ sharedWithUser: { operator: "=", values: [sharer.id.to_s] } }]
  end
  let(:timestamps) { [baseline_time, Timestamp.now] }

  # The frontend joins the query's timestamps verbatim (url-params-helper.ts:209), so the current
  # one stays the relative "PT0S". api_v3_paths.path_for would absolutize it, which turns it
  # historic and moves the Loader to its historic branch; see the describe block at the bottom.
  let(:path) do
    "#{api_v3_paths.work_packages}?" \
      "#{{ filters: filters.to_json, timestamps: timestamps.join(',') }.to_query}"
  end

  def element_index_of(work_package)
    ids = JSON.parse(api_response.body).dig("_embedded", "elements").pluck("id")
    ids.index(work_package.id) or raise "#{work_package.id} not among #{ids.inspect}"
  end

  def meta_at(work_package, timestamp_index)
    JSON.parse(api_response.body)
        .dig("_embedded", "elements", element_index_of(work_package),
             "_embedded", "attributesByTimestamp", timestamp_index, "_meta")
  end

  def self_link_timestamps
    href = JSON.parse(api_response.body).dig("_links", "self", "href")
    CGI.parse(URI.parse(href).query.to_s)["timestamps"].first
  end

  describe "without timestamps (control)" do
    let(:path) { "#{api_v3_paths.work_packages}?#{{ filters: filters.to_json }.to_query}" }

    it "returns only the work packages actually shared with the filtered user" do
      expect(api_response.status).to be 200
      expect(JSON.parse(api_response.body)["total"]).to eq 2
      expect(JSON.parse(api_response.body).dig("_embedded", "elements").pluck("id"))
        .to contain_exactly(shared_work_package.id, newly_shared_work_package.id)
    end
  end

  describe "with a baseline timestamp" do
    it "succeeds" do
      expect(api_response.status).to be 200
    end

    it "returns every visible work package, not only the shared ones" do
      expect(JSON.parse(api_response.body)["total"]).to eq 3
      expect(JSON.parse(api_response.body).dig("_embedded", "elements").pluck("id"))
        .to contain_exactly(shared_work_package.id,
                            unrelated_work_package.id,
                            newly_shared_work_package.id)
    end

    # base.matchesFilters && !compare.matchesFilters renders the row as "removed"
    # (baseline-helpers.ts:101), claiming a share was revoked that never existed.
    it "reports a never-shared work package as matching the filters at the baseline timestamp" do
      expect(meta_at(unrelated_work_package, 0)["matchesFilters"]).to be true
      expect(meta_at(unrelated_work_package, 0)["exists"]).to be true
      expect(meta_at(unrelated_work_package, 1)["matchesFilters"]).to be false
    end

    # "added" requires !base.matchesFilters (baseline-helpers.ts:99), so a share created since
    # the baseline is not marked as added.
    it "reports a work package shared after the baseline as already matching at the baseline" do
      expect(meta_at(newly_shared_work_package, 0)["matchesFilters"]).to be true
      expect(meta_at(newly_shared_work_package, 0)["exists"]).to be true
      expect(meta_at(newly_shared_work_package, 1)["matchesFilters"]).to be true
    end

    it "hands back absolute timestamps in its own self link" do
      expect(self_link_timestamps).not_to include("PT0S")
    end
  end

  # A work package created after the baseline is the case where applying `filter_merges` to the
  # current timestamp would remove a row rather than only mislabel one: it exists at the current
  # timestamp only, so whether the filter narrows that timestamp decides whether it appears at all.
  describe "with a work package created after the baseline" do
    let!(:created_after_baseline) do
      create(:work_package,
             project:,
             subject: "Created after the baseline, never shared",
             created_at: baseline_time.to_time + 1.day,
             journals: { baseline_time.to_time + 1.day => {} })
    end

    it "returns it, because the filter narrows neither timestamp" do
      expect(JSON.parse(api_response.body)["total"]).to eq 4
      expect(JSON.parse(api_response.body).dig("_embedded", "elements").pluck("id"))
        .to include(created_after_baseline.id)
    end

    it "reports it as not existing at the baseline" do
      expect(meta_at(created_after_baseline, 0)["exists"]).to be false
    end
  end

  # The collection absolutizes both timestamps for its self and pagination links
  # (work_package_collection_representer.rb:60). An absolute "now" is `historic?`, so following
  # such a link evaluates the current timestamp through the journals as well and drops
  # `filter_merges` from that side too. The badge computed for the very same row therefore
  # differs between the response and the links that response hands back.
  describe "with the absolute timestamps the collection's own links carry" do
    let(:timestamps) { [baseline_time, Timestamp.now].map(&:absolute) }

    it "reports a never-shared work package as matching at both timestamps" do
      expect(meta_at(unrelated_work_package, 0)["matchesFilters"]).to be true
      expect(meta_at(unrelated_work_package, 1)["matchesFilters"]).to be true
    end
  end
end
