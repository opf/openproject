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

RSpec.describe TestManagement::TestRunCase do
  let(:run_case) { create(:tm_test_run_case) }

  it "validates the status" do
    run_case.status = "bogus"
    expect(run_case).not_to be_valid
  end

  it "is unique per run and case" do
    duplicate = described_class.new(test_run: run_case.test_run, test_case: run_case.test_case)
    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "uses the frozen status once the run is finished" do
    run_case.update!(status: "passed")
    expect(run_case.effective_status).to eq("passed")

    run_case.update_columns(final_status: "failed")
    expect(run_case.reload.effective_status).to eq("failed")
  end

  it "is frozen when its run is finished" do
    expect(run_case).not_to be_status_frozen
    run_case.test_run.update!(state: "completed")
    expect(run_case.reload).to be_status_frozen
    expect(run_case).not_to be_frozen # ActiveRecord's own frozen? is untouched
  end

  it "returns the latest result" do
    create(:tm_test_result, run_case:, status: "failed")
    latest = create(:tm_test_result, run_case:, status: "passed")

    expect(run_case.last_result).to eq(latest)
  end

  it "is removed with its run and with its test case" do
    other = create(:tm_test_run_case)
    run_case.test_run.destroy
    other.test_case.destroy

    expect(described_class.where(id: [run_case.id, other.id])).to be_empty
  end
end
