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
require_relative "shared_examples"

# Scenarios specified in https://community.openproject.org/wp/40749
RSpec.describe WorkPackages::SetAttributesService::DeriveProgressValuesStatusBased,
               type: :model,
               with_settings: { work_package_done_ratio: "status" } do
  shared_let(:status_0_pct_complete) { create(:status, default_done_ratio: 0, name: "0% complete") }
  shared_let(:status_50_pct_complete) { create(:status, default_done_ratio: 50, name: "50% complete") }
  shared_let(:status_70_pct_complete) { create(:status, default_done_ratio: 70, name: "70% complete") }

  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:, status: status_0_pct_complete) }
  let(:instance) { described_class.new(work_package) }

  context "given a work package with work, remaining work, and status with % complete being set" do
    before do
      work_package.status = status_50_pct_complete
      work_package.done_ratio = work_package.status.default_done_ratio
      work_package.estimated_hours = 10.0
      work_package.remaining_hours = 5.0
      work_package.clear_changes_information
    end

    context "when work is cleared" do
      let(:set_attributes) { { estimated_hours: nil } }
      let(:expected_derived_attributes) { { remaining_hours: nil } }

      include_examples "update progress values", description: "clears remaining work",
                                                 expected_hints: {
                                                   remaining_work: :cleared_because_work_is_empty
                                                 }
    end

    context "when work is changed" do
      let(:set_attributes) { { estimated_hours: 5.0 } }
      let(:expected_derived_attributes) { { remaining_hours: 2.5 } }

      include_examples "update progress values", description: "derives remaining work",
                                                 expected_hints: {
                                                   remaining_work: :derived
                                                 }
    end

    context "when work is changed to a negative value" do
      let(:set_attributes) { { estimated_hours: -1.0 } }
      let(:expected_kept_attributes) { %w[remaining_hours] }

      include_examples "update progress values",
                       description: "is an error state (to be detected by contract), and remaining work is kept",
                       expected_hints: {}
    end

    context "when another status is set" do
      let(:set_attributes) { { status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { remaining_hours: 3.0 } }

      include_examples "update progress values",
                       description: "derives remaining work according to the % complete value of the new status",
                       expected_hints: {
                         remaining_work: :derived
                       }
    end

    context "when floating point operations are inaccurate (2.4000000000000004h)" do
      let(:set_attributes) { { estimated_hours: 8.0, status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { remaining_hours: 2.4 } } # would be 2.4000000000000004 without rounding

      include_examples "update progress values", description: "remaining work is derived and rounded (2.4)",
                                                 expected_hints: {
                                                   remaining_work: :derived
                                                 }
    end
  end

  context "given a work package with work and remaining work being empty, and a status with 0% complete" do
    before do
      work_package.status = status_0_pct_complete
      work_package.done_ratio = work_package.status.default_done_ratio
      work_package.estimated_hours = nil
      work_package.remaining_hours = nil
      work_package.clear_changes_information
    end

    context "when another status with another % complete value is set" do
      let(:set_attributes) { { status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { remaining_hours: nil } }

      include_examples "update progress values",
                       description: "remaining work remains empty",
                       expected_hints: {}
    end

    context "when work is set" do
      let(:set_attributes) { { estimated_hours: 10.0 } }
      let(:expected_derived_attributes) { { remaining_hours: 10.0 } }

      include_examples "update progress values",
                       description: "remaining work is derived from work and % complete value of the status",
                       expected_hints: {
                         remaining_work: :derived
                       }
    end

    context "when work is set to a negative value" do
      let(:set_attributes) { { estimated_hours: -1.0 } }
      let(:expected_kept_attributes) { %w[remaining_hours] }

      include_examples "update progress values",
                       description: "is an error state (to be detected by contract), and remaining work is kept",
                       expected_hints: {}
    end

    context "when work is set with 2nd decimal rounding up" do
      let(:set_attributes) { { estimated_hours: 3.567 } }
      let(:expected_derived_attributes) { { estimated_hours: 3.57, remaining_hours: 3.57 } }

      include_examples "update progress values",
                       description: "values are rounded up to 2 decimals and set to the same value",
                       expected_hints: {
                         remaining_work: :derived
                       }
    end
  end

  context "given a work package with a status with 50% complete" do
    before do
      work_package.status = status_50_pct_complete
      work_package.done_ratio = work_package.status.default_done_ratio
      work_package.clear_changes_information
    end

    context "when another status with another % complete value is set" do
      let(:set_attributes) { { status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { done_ratio: 70 } }

      include_examples "update progress values",
                       description: "sets the % complete value to the status default % complete value",
                       expected_hints: {}
    end

    # can happen if work is set and then is unset
    context "when another status with another % complete value is set and work is cleared" do
      let(:set_attributes) { { status: status_70_pct_complete, estimated_hours: nil } }
      let(:expected_derived_attributes) { { done_ratio: 70 } }

      include_examples "update progress values",
                       description: "sets the % complete value to the status default % complete value",
                       expected_hints: {}
    end
  end
end
