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

RSpec.describe Query::Results,
               "Filtering by version on historic data",
               with_ee: %i[baseline_comparison] do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_work_packages edit_work_packages assign_versions] })
  end
  shared_let(:version_a) { create(:version, project:, name: "Version A") }
  shared_let(:version_b) { create(:version, project:, name: "Version B") }

  shared_let(:created_time) { 5.days.ago }
  shared_let(:historic_time) { 3.days.ago }
  shared_let(:reassigned_time) { 1.day.ago }

  def create_work_package_in_past(subject, version_ids:, kind: "target")
    Timecop.travel(created_time) do
      work_package = build(:work_package, project:, subject:, author: user)
      work_package.public_send(:"#{kind}_version_ids_replacements=", version_ids)
      work_package.save!
      work_package
    end
  end

  # A change to the versions alone is journaled at the database clock, which Timecop does not move.
  # Changing an attribute as well dates the journal at `reassigned_time`.
  def reassign_versions(work_package, version_ids:, kind: "target")
    Timecop.travel(reassigned_time) do
      WorkPackages::UpdateService
        .new(user:, model: work_package)
        .call("#{kind}_version_ids": version_ids, description: "Reassigned")
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:wp_reassigned_from_a_to_b) do
    reassign_versions(create_work_package_in_past("Reassigned from A to B", version_ids: [version_a.id]),
                      version_ids: [version_b.id])
  end
  shared_let(:wp_always_a) { create_work_package_in_past("Always A", version_ids: [version_a.id]) }
  shared_let(:wp_always_b) { create_work_package_in_past("Always B", version_ids: [version_b.id]) }
  shared_let(:wp_assigned_b_later) do
    reassign_versions(create_work_package_in_past("Assigned B later", version_ids: []),
                      version_ids: [version_b.id])
  end

  let(:filter_name) { "version_id" }
  let(:operator) { "=" }
  let(:values) { [version_a.id.to_s] }
  let(:timestamps) { [] }

  let(:query) do
    build(:query, user:, project:, timestamps:) do |q|
      q.filters.clear
      q.add_filter(filter_name, operator, values)
    end
  end

  subject(:results) { described_class.new(query).work_packages }

  before { login_as(user) }

  describe "[prelims]" do
    it "journals the reassignment" do
      expect(wp_reassigned_from_a_to_b.target_version_ids).to eq [version_b.id]
      expect(wp_reassigned_from_a_to_b.at_timestamp(historic_time).target_version_ids).to eq [version_a.id]
      expect(wp_reassigned_from_a_to_b.journals.last.created_at).to be_within(1.minute).of(reassigned_time)
    end
  end

  shared_examples "filtering on the versions assigned at the timestamps" do
    context 'with the "=" operator on version A' do
      context "without timestamps" do
        it "returns only the work packages targeting the version today" do
          expect(results).to contain_exactly(wp_always_a)
        end
      end

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns the work packages that targeted the version back then" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_a)
        end
      end

      context "with the historic and the current timestamp" do
        let(:timestamps) { [historic_time, Timestamp.now] }

        it "returns the work packages targeting the version at any of the timestamps" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_a)
        end
      end
    end

    context 'with the "=" operator on version B' do
      let(:values) { [version_b.id.to_s] }

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns only the work packages that targeted the version back then" do
          expect(results).to contain_exactly(wp_always_b)
        end
      end

      context "with the historic and the current timestamp" do
        let(:timestamps) { [historic_time, Timestamp.now] }

        it "returns the work packages targeting the version at any of the timestamps" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_b, wp_assigned_b_later)
        end
      end
    end

    context 'with the "!" operator on version A' do
      let(:operator) { "!" }

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns the work packages that did not target the version back then" do
          expect(results).to contain_exactly(wp_always_b, wp_assigned_b_later)
        end
      end

      context "with the historic and the current timestamp" do
        let(:timestamps) { [historic_time, Timestamp.now] }

        it "returns the work packages not targeting the version at any of the timestamps" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_b, wp_assigned_b_later)
        end
      end
    end

    context 'with the "*" operator' do
      let(:operator) { "*" }
      let(:values) { [] }

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns the work packages that had a version back then" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_a, wp_always_b)
        end
      end
    end

    context 'with the "!*" operator' do
      let(:operator) { "!*" }
      let(:values) { [] }

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns the work packages that had no version back then" do
          expect(results).to contain_exactly(wp_assigned_b_later)
        end
      end

      context "with the historic and the current timestamp" do
        let(:timestamps) { [historic_time, Timestamp.now] }

        it "returns the work packages without a version at any of the timestamps" do
          expect(results).to contain_exactly(wp_assigned_b_later)
        end
      end
    end

    context 'with the "o" operator' do
      let(:operator) { "o" }
      let(:values) { [] }

      context "with only the historic timestamp" do
        let(:timestamps) { [historic_time] }

        it "returns the work packages that had a currently open version back then" do
          expect(results).to contain_exactly(wp_reassigned_from_a_to_b, wp_always_a, wp_always_b)
        end
      end
    end
  end

  context "with the legacy version filter",
          with_settings: { work_package_multiple_versions: false } do
    it_behaves_like "filtering on the versions assigned at the timestamps"
  end

  context "with the target versions filter",
          with_settings: { work_package_multiple_versions: true } do
    let(:filter_name) { "target_version_id" }

    it_behaves_like "filtering on the versions assigned at the timestamps"
  end

  context "with the observed in versions filter" do
    shared_let(:wp_observed_reassigned_from_a_to_b) do
      reassign_versions(create_work_package_in_past("Observed in A then B", version_ids: [version_a.id], kind: "observed_in"),
                        version_ids: [version_b.id],
                        kind: "observed_in")
    end

    let(:filter_name) { "observed_in_version_id" }
    let(:timestamps) { [historic_time] }

    it "returns the work packages that were observed in the version back then" do
      expect(results).to contain_exactly(wp_observed_reassigned_from_a_to_b)
    end
  end
end
