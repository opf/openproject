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

require "spec_helper"

RSpec.describe "Test run transitions" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:manager) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:uploader) { create(:user, member_with_permissions: { project => %i[view_test_runs upload_test_results] }) }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_test_runs execute_test_runs] }) }
  let(:run) { create(:tm_test_run, :in_progress, project:) }
  let!(:passed) { create(:tm_test_run_case, test_run: run, status: "passed") }
  let!(:failed) { create(:tm_test_run_case, test_run: run, status: "failed") }

  describe TestManagement::TestRuns::CompleteService do
    it "completes and freezes statuses" do
      result = described_class.new(user: manager, model: run).call

      expect(result).to be_success
      expect(run.reload).to have_attributes(state: "completed", finished_by: manager)
      expect(run.finished_at).to be_present
      expect(passed.reload.final_status).to eq("passed")
      expect(failed.reload.final_status).to eq("failed")
    end

    it "can be called by test automation (upload_test_results)" do
      expect(described_class.new(user: uploader, model: run).call).to be_success
    end

    it "is refused without permission" do
      result = described_class.new(user: viewer, model: run).call

      expect(result).not_to be_success
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
      expect(run.reload.state).to eq("in_progress")
    end

    it "is refused for a finished run" do
      described_class.new(user: manager, model: run).call
      result = described_class.new(user: manager, model: run.reload).call

      expect(result.errors.symbols_for(:base)).to include(:tm_invalid_transition)
    end
  end

  describe TestManagement::TestRuns::CancelService do
    it "cancels and freezes statuses" do
      expect(described_class.new(user: manager, model: run).call).to be_success
      expect(run.reload.state).to eq("cancelled")
      expect(failed.reload.final_status).to eq("failed")
    end

    it "is not available to automation users" do
      expect(described_class.new(user: uploader, model: run).call).not_to be_success
    end
  end

  describe TestManagement::TestRuns::ReopenService do
    before { TestManagement::TestRuns::CompleteService.new(user: manager, model: run).call }

    it "reopens to in_progress and releases frozen statuses" do
      result = described_class.new(user: manager, model: run.reload).call

      expect(result).to be_success
      expect(run.reload).to have_attributes(state: "in_progress", finished_at: nil, finished_by: nil)
      expect(passed.reload.final_status).to be_nil
    end

    it "adds cases created while an all-run was closed" do
      run.update_columns(selection_mode: "all")
      late = create(:tm_test_case, project:)
      described_class.new(user: manager, model: run.reload).call

      expect(run.test_cases).to include(late)
    end

    it "is refused for an active run" do
      described_class.new(user: manager, model: run.reload).call
      expect(described_class.new(user: manager, model: run.reload).call).not_to be_success
    end
  end
end
