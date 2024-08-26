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

RSpec.describe API::V3::WorkPackages::WorkPackageRepresenter do
  include API::V3::Utilities::PathHelper

  let(:additional_permissions) do
    %i[
      view_time_entries
      view_cost_entries
      view_cost_rates
    ]
  end

  let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { project => [:view_work_packages] + additional_permissions })
  end

  let(:cost_entry_1) do
    create(:cost_entry,
           work_package:,
           project:,
           units: 3,
           spent_on: Time.zone.today,
           user:,
           comments: "Entry 1")
  end
  let(:cost_entry_2) do
    create(:cost_entry,
           work_package:,
           project:,
           units: 3,
           spent_on: Time.zone.today,
           user:,
           comments: "Entry 2")
  end

  let(:work_package) do
    create(:work_package,
           project_id: project.id)
  end
  let(:representer) do
    described_class.create(work_package,
                           current_user: user,
                           embed_links: true)
  end

  before do
    allow(User).to receive(:current).and_return user
  end

  subject(:generated) { representer.to_json }

  describe "generation" do
    before do
      cost_entry_1
      cost_entry_2
    end

    describe "work_package" do
      # specifying as it used to be different
      it { is_expected.to have_json_path("spentTime") }

      it { is_expected.not_to have_json_path("spentHours") }

      it { is_expected.to have_json_path("overallCosts") }

      it_behaves_like "has an untitled link" do
        let(:link) { "costsByType" }
        let(:href) { api_v3_paths.summarized_work_package_costs_by_type work_package.id }
      end

      it "embeds the costsByType" do
        expect(subject).to have_json_path("_embedded/costsByType")
      end

      describe "spentTime" do
        context "time entry with single hour" do
          let(:time_entry) do
            create(:time_entry,
                   project: work_package.project,
                   work_package:,
                   hours: 1.0)
          end

          before { time_entry }

          it { is_expected.to be_json_eql("PT1H".to_json).at_path("spentTime") }
        end

        context "time entry with multiple hours" do
          let(:time_entry) do
            create(:time_entry,
                   project: work_package.project,
                   work_package:,
                   hours: 42.5)
          end

          before { time_entry }

          it { is_expected.to be_json_eql("P1DT18H30M".to_json).at_path("spentTime") }
        end

        context "no view_time_entries permission" do
          let(:additional_permissions) { [] }

          it { is_expected.not_to have_json_path("spentTime") }
        end

        context "only view_own_time_entries permission" do
          let(:user2) do
            create(:user, member_with_permissions: { project => %i[view_own_time_entries view_work_packages] })
          end

          let!(:own_time_entry) do
            create(:time_entry,
                   project: work_package.project,
                   work_package:,
                   hours: 2,
                   user: user2)
          end

          let!(:other_time_entry) do
            create(:time_entry,
                   project: work_package.project,
                   work_package:,
                   hours: 1,
                   user:)
          end

          before do
            allow(User).to receive(:current).and_return(user2)
          end

          it { is_expected.to be_json_eql("PT2H".to_json).at_path("spentTime") }
        end

        context "no time entry" do
          it { is_expected.to be_json_eql("PT0S".to_json).at_path("spentTime") }
        end
      end

      describe "laborCosts" do
        before do
          allow(work_package).to receive(:labor_costs).and_return(6000.0)
        end

        context "with the :view_hourly_rates and :view_time_entries permission" do
          let(:additional_permissions) { %i[view_hourly_rates view_time_entries] }

          it "is expected to have a laborCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("laborCosts")
          end
        end

        context "with the :view_own_hourly_rate and :view_own_time_entries permission" do
          let(:additional_permissions) { %i[view_own_hourly_rate view_own_time_entries] }

          it "is expected to have a laborCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("laborCosts")
          end
        end

        context "without the user having permission" do
          it "has no attribute" do
            expect(subject).not_to have_json_path("laborCosts")
          end
        end
      end

      describe "materialCosts" do
        before do
          allow(work_package).to receive(:material_costs).and_return(6000.0)
        end

        context "with the :view_own_cost_entries and :view_cost_rates permission" do
          let(:additional_permissions) { %i[view_own_cost_entries view_cost_rates] }

          it "is expected to have a materialCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("materialCosts")
          end
        end

        context "with the :view_cost_entries and :view_cost_rates permission" do
          let(:additional_permissions) { %i[view_cost_entries view_cost_rates] }

          it "is expected to have a materialCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("materialCosts")
          end
        end

        context "without the user having permission" do
          let(:additional_permissions) { [] }

          it "has no attribute" do
            expect(subject).not_to have_json_path("materialCosts")
          end
        end
      end

      describe "overallCosts" do
        before do
          allow(work_package).to receive(:overall_costs).and_return(6000.0)
        end

        context "with the :view_hourly_rates and :view_time_entries permission" do
          let(:additional_permissions) { %i[view_hourly_rates view_time_entries] }

          it "is expected to have a overallCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("overallCosts")
          end
        end

        context "with the :view_own_hourly_rate and :view_own_time_entries permission" do
          let(:additional_permissions) { %i[view_own_time_entries view_own_hourly_rate] }

          it "is expected to have a overallCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("overallCosts")
          end
        end

        context "with the :view_own_cost_entries and :view_cost_rates permission" do
          let(:additional_permissions) { %i[view_own_cost_entries view_cost_rates] }

          it "is expected to have a overallCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("overallCosts")
          end
        end

        context "with the :view_cost_entries and :view_cost_rates permission" do
          let(:additional_permissions) { %i[view_cost_entries view_cost_rates] }

          it "is expected to have a overallCosts attribute" do
            expect(subject).to be_json_eql("6,000.00 EUR".to_json).at_path("overallCosts")
          end
        end

        context "without the user having permission" do
          let(:additional_permissions) { [] }

          it "has no attribute" do
            expect(subject).not_to have_json_path("overallCosts")
          end
        end
      end
    end
  end

  describe "_links" do
    describe "move" do
      it_behaves_like "has a titled action link" do
        let(:link) { "logCosts" }
        let(:href) { new_work_packages_cost_entry_path(work_package) }
        let(:permission) { %i(log_costs log_own_costs) }
        let(:title) { "Log costs on #{work_package.subject}" }
      end
    end

    describe "timeEntries" do
      context "with the :view_time_entries permission" do
        let(:additional_permissions) { %i[view_time_entries] }

        it "has timeEntries link" do
          expect(subject).to have_json_path("_links/timeEntries/href")
        end
      end

      context "with the :view_own_time_entries permission" do
        let(:additional_permissions) { %i[view_own_time_entries] }

        it "has timeEnries link" do
          expect(subject).to have_json_path("_links/timeEntries/href")
        end
      end
    end
  end

  describe "costs module disabled" do
    before do
      allow(work_package).to receive(:costs_enabled?).and_return false
    end

    describe "work_package" do
      it { is_expected.to have_json_path("spentTime") }

      it { is_expected.not_to have_json_path("spentHours") }

      describe "embedded" do
        it { is_expected.not_to have_json_path("_embedded/summarizedCostEntries") }
      end
    end

    describe "_links" do
      it { is_expected.not_to have_json_path("_links/log_costs") }
    end
  end
end
