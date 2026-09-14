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

RSpec.describe Query::Results, "sums" do
  shared_let(:int_cf) do
    create(:integer_wp_custom_field)
  end
  shared_let(:float_cf) do
    create(:float_wp_custom_field)
  end
  shared_let(:type) do
    create(:type) do |t|
      t.default_variant.custom_fields << int_cf
      t.default_variant.custom_fields << float_cf
    end
  end
  shared_let(:project) do
    create(:project) do |p|
      p.project_types.create!(type:)
      p.work_package_custom_fields << int_cf
      p.work_package_custom_fields << float_cf
    end
  end
  shared_let(:other_project) do
    create(:project) do |p|
      p.project_types.create!(type:)
      p.work_package_custom_fields << int_cf
      p.work_package_custom_fields << float_cf
    end
  end
  shared_let(:current_user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages view_cost_entries view_time_entries view_cost_rates view_hourly_rates]
           })
  end
  shared_let(:priority) { create(:priority, name: "Normal") }
  shared_let(:status_new) { create(:status, name: "New") }

  before_all do
    set_factory_default(:user, current_user)
    set_factory_default(:priority, priority)
    set_factory_default(:project, project)
    set_factory_default(:project_with_types, project)
    set_factory_default(:status, status_new)
  end

  shared_let(:work_package1) do
    create(:work_package,
           type:,
           estimated_hours: 10,
           remaining_hours: 9,
           done_ratio: 10,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           story_points: 7) do |wp|
             wp.cost_entries << create(:cost_entry,
                                       entity: wp,
                                       overridden_costs: 200)
             wp.time_entries << create(:time_entry,
                                       entity: wp,
                                       overridden_costs: 300)
           end
  end
  shared_let(:work_package2) do
    create(:work_package,
           type:,
           assigned_to: current_user,
           estimated_hours: 5,
           remaining_hours: 2.5,
           done_ratio: 50,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           story_points: 7) do |wp|
             wp.cost_entries << create(:cost_entry,
                                       entity: wp,
                                       overridden_costs: 200)
             wp.time_entries << create(:time_entry,
                                       entity: wp,
                                       overridden_costs: 300)
           end
  end
  shared_let(:work_package3) do
    create(:work_package,
           type:,
           assigned_to: current_user,
           responsible: current_user,
           estimated_hours: 5,
           remaining_hours: 2.5,
           done_ratio: 50,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           story_points: 7)
  end
  shared_let(:work_package_with_done_ratio_only) do
    create(:work_package,
           type:,
           done_ratio: 100)
  end
  shared_let(:invisible_work_package1) do
    create(:work_package,
           type:,
           project: other_project,
           estimated_hours: 5,
           remaining_hours: 3,
           done_ratio: 40,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           story_points: 7)
  end
  let(:group_by) { nil }
  let(:query) do
    build(:query,
          project:,
          group_by:)
  end
  let(:query_results) do
    described_class.new query
  end

  before do
    login_as(current_user)
  end

  def stringify_column_keys(sums_hash)
    sums_hash.transform_keys { |column| column.name.to_s }
  end

  describe "#all_total_sums" do
    it "is a hash of all summable columns" do
      expect(stringify_column_keys(query_results.all_total_sums))
        .to eq("estimated_hours" => 20.0,
               "remaining_hours" => 14.0,
               "done_ratio" => 30,
               int_cf.column_name => 30,
               float_cf.column_name => 10.24,
               "material_costs" => 400.0,
               "labor_costs" => 600.0,
               "overall_costs" => 1000.0,
               "story_points" => 21)
    end

    context "when filtering" do
      before do
        query.add_filter("assigned_to_id", "=", [current_user.id.to_s])
      end

      it "is a hash of all summable columns and includes only the work packages matching the filter" do
        expect(stringify_column_keys(query_results.all_total_sums))
          .to eq("estimated_hours" => 10.0,
                 "remaining_hours" => 5.0,
                 "done_ratio" => 50,
                 int_cf.column_name => 20,
                 float_cf.column_name => 6.83,
                 "material_costs" => 200.0,
                 "labor_costs" => 300.0,
                 "overall_costs" => 500.0,
                 "story_points" => 14)
      end
    end

    describe "% complete sum" do
      subject(:percent_complete_sum) { stringify_column_keys(query_results.all_total_sums)["done_ratio"] }

      context "when using work weighted average mode",
              with_settings: { total_percent_complete_mode: "work_weighted_average" } do
        it "is computed from work and remaining work sums " \
           "and ignores work packages having only % complete set" do
          # work sum: 10 + 5 + 5 = 20
          # remaining work sum: 9 + 2.5 + 2.5 = 14
          # % complete sum: 100 * (20 - 14) / 20 = 30
          expect(percent_complete_sum).to eq(30)
        end

        context "when work and remaining work are 0h" do
          before do
            WorkPackage.update_all(estimated_hours: 0, remaining_hours: 0, done_ratio: nil)
          end

          it "is unset" do
            expect(percent_complete_sum).to be_nil
          end
        end

        context "when work sum is more than 0h and remaining work sum is 0h" do
          before do
            WorkPackage.update_all(estimated_hours: 5, remaining_hours: 0, done_ratio: 100)
          end

          it "is 100%" do
            expect(percent_complete_sum).to eq(100)
          end
        end

        context "when work sum is equal to remaining work sum" do
          before do
            WorkPackage.update_all(estimated_hours: 5, remaining_hours: 5, done_ratio: 0)
          end

          it "is 0%" do
            expect(percent_complete_sum).to eq(0)
          end
        end

        context "when % complete sum is not exactly 100% (like 99.9%)" do
          before do
            WorkPackage.update_all(estimated_hours: 1000, remaining_hours: 1, done_ratio: 99)
          end

          it "is 99% because it's not strictly 100%" do
            expect(percent_complete_sum).to eq(99)
          end
        end

        context "when % complete sum is not exactly 0% (like 0.1%)" do
          before do
            WorkPackage.update_all(estimated_hours: 1000, remaining_hours: 999, done_ratio: 1)
          end

          it "is 1% because it's not strictly 0%" do
            expect(percent_complete_sum).to eq(1)
          end
        end
      end

      context "when using simple average mode",
              with_settings: { total_percent_complete_mode: "simple_average" } do
        it "is computed from % complete values of work packages having % complete set " \
           "and ignores work and remaining work values" do
          # % complete sum: (10 + 50 + 50 + 100) / 4.0 = 52.5 => 53% rounded
          expect(percent_complete_sum).to eq(53)
        end

        context "when none have % complete set" do
          before do
            WorkPackage.update_all(estimated_hours: 0, remaining_hours: 0, done_ratio: nil)
          end

          it "is unset" do
            expect(percent_complete_sum).to be_nil
          end
        end

        context "when all % complete are 100%" do
          before do
            WorkPackage.update_all(estimated_hours: 5, remaining_hours: 0, done_ratio: 100)
          end

          it "is 100%" do
            expect(percent_complete_sum).to eq(100)
          end
        end

        context "when all % complete are 0%" do
          before do
            WorkPackage.update_all(estimated_hours: 5, remaining_hours: 5, done_ratio: 0)
          end

          it "is 0%" do
            expect(percent_complete_sum).to eq(0)
          end
        end

        context "when % complete average is not exactly 100% (like 99.9%)" do
          before do
            WorkPackage.update_all(estimated_hours: 1000, remaining_hours: 0, done_ratio: 100)
            WorkPackage.first.update(estimated_hours: 1000, remaining_hours: 1, done_ratio: 99)
          end

          it "is 99% because it's not strictly 100%" do
            expect(percent_complete_sum).to eq(99)
          end
        end

        context "when % complete sum is not exactly 0% (like 0.1%)" do
          before do
            WorkPackage.update_all(estimated_hours: 1000, remaining_hours: 1000, done_ratio: 0)
            WorkPackage.first.update(estimated_hours: 1000, remaining_hours: 999, done_ratio: 1)
          end

          it "is 1% because it's not strictly 0%" do
            expect(percent_complete_sum).to eq(1)
          end
        end

        context "when % complete sum decimal part is above 0.5 (like 2.6%)" do
          before do
            # 4x3% and 1x1% => 13 / 5 = 2.6%
            WorkPackage.update_all(estimated_hours: 100, remaining_hours: 97, done_ratio: 3)
            WorkPackage.first.update(estimated_hours: 100, remaining_hours: 99, done_ratio: 1)
          end

          it "is rounded up (to 3%)" do
            expect(percent_complete_sum).to eq(3)
          end
        end
      end
    end
  end

  describe "#all_sums_for_group" do
    context "when grouped by assigned_to" do
      let(:group_by) { :assigned_to }

      it "is a hash of sums grouped by user values (and nil) and grouped columns" do
        expect(query_results.all_group_sums.keys).to contain_exactly(current_user, nil)
        expect(stringify_column_keys(query_results.all_group_sums[current_user]))
          .to eq("estimated_hours" => 10.0,
                 "remaining_hours" => 5.0,
                 "done_ratio" => 50,
                 int_cf.column_name => 20,
                 float_cf.column_name => 6.83,
                 "material_costs" => 200.0,
                 "labor_costs" => 300.0,
                 "overall_costs" => 500.0,
                 "story_points" => 14)
        expect(stringify_column_keys(query_results.all_group_sums[nil]))
          .to eq("estimated_hours" => 10.0,
                 "remaining_hours" => 9.0,
                 "done_ratio" => 10,
                 int_cf.column_name => 10,
                 float_cf.column_name => 3.41,
                 "material_costs" => 200.0,
                 "labor_costs" => 300.0,
                 "overall_costs" => 500.0,
                 "story_points" => 7)
      end

      context "when filtering" do
        before do
          query.add_filter("responsible_id", "=", [current_user.id.to_s])
        end

        it "is a hash of sums grouped by user values and grouped columns" do
          expect(query_results.all_group_sums.keys).to contain_exactly(current_user)
          expect(stringify_column_keys(query_results.all_group_sums[current_user]))
            .to eq("estimated_hours" => 5.0,
                   "remaining_hours" => 2.5,
                   "done_ratio" => 50,
                   int_cf.column_name => 10,
                   float_cf.column_name => 3.41,
                   "material_costs" => 0.0,
                   "labor_costs" => 0.0,
                   "overall_costs" => 0.0,
                   "story_points" => 7)
        end
      end
    end

    context "when grouped by done_ratio" do
      let(:group_by) { :done_ratio }

      it "is a hash of sums grouped by done_ratio values and grouped columns" do
        expect(query_results.all_group_sums.keys).to contain_exactly(100, 50, 10)
        expect(stringify_column_keys(query_results.all_group_sums[100]))
          .to eq("estimated_hours" => nil,
                 "remaining_hours" => nil,
                 "done_ratio" => nil,
                 int_cf.column_name => nil,
                 float_cf.column_name => nil,
                 "material_costs" => 0.0,
                 "labor_costs" => 0.0,
                 "overall_costs" => 0.0,
                 "story_points" => nil)
        expect(stringify_column_keys(query_results.all_group_sums[50]))
          .to eq("estimated_hours" => 10.0,
                 "remaining_hours" => 5.0,
                 "done_ratio" => 50,
                 int_cf.column_name => 20,
                 float_cf.column_name => 6.83,
                 "material_costs" => 200.0,
                 "labor_costs" => 300.0,
                 "overall_costs" => 500.0,
                 "story_points" => 14)
        expect(stringify_column_keys(query_results.all_group_sums[10]))
           .to eq("estimated_hours" => 10.0,
                  "remaining_hours" => 9.0,
                  "done_ratio" => 10,
                  int_cf.column_name => 10,
                  float_cf.column_name => 3.41,
                  "material_costs" => 200.0,
                  "labor_costs" => 300.0,
                  "overall_costs" => 500.0,
                  "story_points" => 7)
      end

      context "when filtering" do
        before do
          query.add_filter("responsible_id", "=", [current_user.id.to_s])
        end

        it "is a hash of sums grouped by done_ratio values and grouped columns" do
          expect(query_results.all_group_sums.keys).to contain_exactly(50)
          expect(stringify_column_keys(query_results.all_group_sums[50]))
            .to eq("estimated_hours" => 5.0,
                   "remaining_hours" => 2.5,
                   "done_ratio" => 50,
                   int_cf.column_name => 10,
                   float_cf.column_name => 3.41,
                   "material_costs" => 0.0,
                   "labor_costs" => 0.0,
                   "overall_costs" => 0.0,
                   "story_points" => 7)
        end
      end
    end
  end
end
