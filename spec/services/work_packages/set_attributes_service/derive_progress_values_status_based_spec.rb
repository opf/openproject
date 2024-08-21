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

  shared_examples_for "update progress values" do |description:|
    subject do
      allow(work_package)
        .to receive(:save)

      instance.call
    end

    it description do
      work_package.attributes = set_attributes
      all_expected_attributes = {}
      all_expected_attributes.merge!(expected_derived_attributes) if defined?(expected_derived_attributes)
      if defined?(expected_kept_attributes)
        kept = work_package.attributes.slice(*expected_kept_attributes)
        if kept.size != expected_kept_attributes.size
          raise ArgumentError, "expected_kept_attributes contains attributes that are not present in the work_package: " \
                               "#{expected_kept_attributes - kept.keys} not present in #{work_package.attributes}"
        end
        all_expected_attributes.merge!(kept)
      end
      next if all_expected_attributes.blank?

      subject

      aggregate_failures do
        expect(work_package).to have_attributes(all_expected_attributes)
        # work package is not saved and no errors are created
        expect(work_package).not_to have_received(:save)
        expect(work_package.errors).to be_empty
      end
    end
  end

  context "given a work package with work, remaining work, and status with % complete being set" do
    before do
      work_package.status = status_50_pct_complete
      work_package.done_ratio = work_package.status.default_done_ratio
      work_package.estimated_hours = 10.0
      work_package.remaining_hours = 5.0
      work_package.clear_changes_information
    end

    context "when work is unset" do
      let(:set_attributes) { { estimated_hours: nil } }
      let(:expected_derived_attributes) { { remaining_hours: nil } }

      include_examples "update progress values", description: "unsets remaining work"
    end

    context "when work is changed" do
      let(:set_attributes) { { estimated_hours: 5.0 } }
      let(:expected_derived_attributes) { { remaining_hours: 2.5 } }

      include_examples "update progress values", description: "recomputes remaining work accordingly"
    end

    context "when work is changed to a negative value" do
      let(:set_attributes) { { estimated_hours: -1.0 } }
      let(:expected_kept_attributes) { %w[remaining_hours] }

      include_examples "update progress values",
                       description: "is an error state (to be detected by contract), and remaining work is kept"
    end

    context "when another status is set" do
      let(:set_attributes) { { status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { remaining_hours: 3.0 } }

      include_examples "update progress values",
                       description: "recomputes remaining work according to the % complete value of the new status"
    end

    context "when floating point operations are inaccurate (2.4000000000000004h)" do
      let(:set_attributes) { { estimated_hours: 8.0, status: status_70_pct_complete } }
      let(:expected_derived_attributes) { { remaining_hours: 2.4 } } # would be 2.4000000000000004 without rounding

      include_examples "update progress values", description: "remaining work is computed and rounded (2.4)"
    end
  end

  context "given a work package with work and remaining work unset, and a status with 0% complete" do
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
                       description: "remaining work remains unset"
    end

    context "when work is set" do
      let(:set_attributes) { { estimated_hours: 10.0 } }
      let(:expected_derived_attributes) { { remaining_hours: 10.0 } }

      include_examples "update progress values",
                       description: "remaining work is updated accordingly from work and % complete value of the status"
    end

    context "when work is set to a negative value" do
      let(:set_attributes) { { estimated_hours: -1.0 } }
      let(:expected_kept_attributes) { %w[remaining_hours] }

      include_examples "update progress values",
                       description: "is an error state (to be detected by contract), and remaining work is kept"
    end

    context "when work is set with 2nd decimal rounding up" do
      let(:set_attributes) { { estimated_hours: 3.567 } }
      let(:expected_derived_attributes) { { estimated_hours: 3.57, remaining_hours: 3.57 } }

      include_examples "update progress values",
                       description: "values are rounded up to 2 decimals and set to the same value"
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
                       description: "sets the % complete value to the status default % complete value"
    end
  end
end
