# frozen_string_literal: true

# -- copyright
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
# ++
#

require "spec_helper"

RSpec.describe Admin::Settings::ProgressTrackingController do
  shared_let(:user) { create(:admin) }

  current_user { user }

  include_examples "GET #show requires admin permission and renders template", path: "progress_tracking"

  context "when changing progress calculation from work-based to status-based" do
    shared_let(:status) { create(:status, default_done_ratio: 42) }
    shared_let(:work_package) { create(:work_package, status:, done_ratio: 10, estimated_hours: 100) }

    before do
      Setting.work_package_done_ratio = "field"
    end

    it "starts a job to update work packages % complete and remaining work values" do
      patch "update",
            params: {
              settings: {
                work_package_done_ratio: "status"
              }
            }
      expect(Setting.work_package_done_ratio).to eq("status")
      expect(WorkPackages::Progress::ApplyStatusesChangeJob)
        .to have_been_enqueued.with(cause_type: "progress_mode_changed_to_status_based")

      perform_enqueued_jobs

      expect(work_package.reload.read_attribute(:done_ratio)).to eq(status.default_done_ratio)
      expect(work_package.last_journal.details["cause"]).to eq([nil, { "type" => "progress_mode_changed_to_status_based" }])
    end
  end

  context "when sending patch request to change progress calculation from status-based to status-based" do
    before do
      Setting.work_package_done_ratio = "status"
    end

    it "does not start a job" do
      patch "update",
            params: {
              settings: {
                work_package_done_ratio: "status"
              }
            }
      expect(WorkPackages::Progress::ApplyStatusesChangeJob)
        .not_to have_been_enqueued
    end
  end

  context "when changing progress calculation from status-based to work-based" do
    before do
      Setting.work_package_done_ratio = "status"
    end

    it "does not start a job" do
      patch "update",
            params: {
              settings: {
                work_package_done_ratio: "field"
              }
            }
      expect(WorkPackages::Progress::ApplyStatusesChangeJob)
        .not_to have_been_enqueued
    end
  end

  context "when changing total percent complete mode from simple average to work-weighted average" do
    before do
      Setting.total_percent_complete_mode = "simple_average"
    end

    it "starts a job to update work packages' total % complete values" do
      patch "update",
            params: {
              settings: {
                total_percent_complete_mode: "work_weighted_average"
              }
            }
      expect(WorkPackages::Progress::ApplyTotalPercentCompleteModeChangeJob)
        .to have_been_enqueued.with(mode: "work_weighted_average",
                                    cause_type: "total_percent_complete_mode_changed_to_work_weighted_average")

      perform_enqueued_jobs

      expect(Setting.total_percent_complete_mode).to eq("work_weighted_average")
    end
  end

  context "when changing total percent complete mode from work-weighted average to simple average" do
    before do
      Setting.total_percent_complete_mode = "work_weighted_average"
    end

    it "starts a job to update work packages' total % complete values" do
      patch "update",
            params: {
              settings: {
                total_percent_complete_mode: "simple_average"
              }
            }
      expect(WorkPackages::Progress::ApplyTotalPercentCompleteModeChangeJob)
        .to have_been_enqueued.with(mode: "simple_average",
                                    cause_type: "total_percent_complete_mode_changed_to_simple_average")

      perform_enqueued_jobs

      expect(Setting.total_percent_complete_mode).to eq("simple_average")
    end
  end
end
