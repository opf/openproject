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
  let(:project) do
    create(:project) do |p|
      p.work_package_custom_fields << int_cf
      p.work_package_custom_fields << float_cf
    end
  end
  let(:estimated_hours_column) { query.displayable_columns.detect { |c| c.name.to_s == "estimated_hours" } }
  let(:int_cf_column) { query.displayable_columns.detect { |c| c.name.to_s == int_cf.column_name } }
  let(:float_cf_column) { query.displayable_columns.detect { |c| c.name.to_s == float_cf.column_name } }
  let(:material_costs_column) { query.displayable_columns.detect { |c| c.name.to_s == "material_costs" } }
  let(:labor_costs_column) { query.displayable_columns.detect { |c| c.name.to_s == "labor_costs" } }
  let(:overall_costs_column) { query.displayable_columns.detect { |c| c.name.to_s == "overall_costs" } }
  let(:remaining_hours_column) { query.displayable_columns.detect { |c| c.name.to_s == "remaining_hours" } }
  let(:story_points_column) { query.displayable_columns.detect { |c| c.name.to_s == "story_points" } }
  let(:other_project) do
    create(:project) do |p|
      p.work_package_custom_fields << int_cf
      p.work_package_custom_fields << float_cf
    end
  end
  let!(:work_package1) do
    create(:work_package,
           type:,
           project:,
           estimated_hours: 10,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           remaining_hours: 9,
           story_points: 7)
  end
  let!(:work_package2) do
    create(:work_package,
           type:,
           project:,
           assigned_to: current_user,
           estimated_hours: 5,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           remaining_hours: 2.5,
           story_points: 7)
  end
  let!(:work_package3) do
    create(:work_package,
           type:,
           project:,
           assigned_to: current_user,
           responsible: current_user,
           estimated_hours: 5,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           remaining_hours: 2.5,
           story_points: 7)
  end
  let!(:invisible_work_package1) do
    create(:work_package,
           type:,
           project: other_project,
           estimated_hours: 5,
           int_cf.attribute_name => 10,
           float_cf.attribute_name => 3.414,
           remaining_hours: 3,
           story_points: 7)
  end
  let!(:cost_entry1) do
    create(:cost_entry,
           project:,
           work_package: work_package1,
           user: current_user,
           overridden_costs: 200)
  end
  let!(:cost_entry2) do
    create(:cost_entry,
           project:,
           work_package: work_package2,
           user: current_user,
           overridden_costs: 200)
  end
  let!(:time_entry1) do
    create(:time_entry,
           project:,
           work_package: work_package1,
           user: current_user,
           overridden_costs: 300)
  end
  let!(:time_entry2) do
    create(:time_entry,
           project:,
           work_package: work_package2,
           user: current_user,
           overridden_costs: 300)
  end
  let(:int_cf) do
    create(:integer_wp_custom_field)
  end
  let(:float_cf) do
    create(:float_wp_custom_field)
  end
  let(:type) do
    create(:type) do |t|
      t.custom_fields << int_cf
      t.custom_fields << float_cf
    end
  end
  let(:current_user) do
    create(:user, member_with_permissions: { project => permissions })
  end
  let(:permissions) do
    %i[view_work_packages view_cost_entries view_time_entries view_cost_rates view_hourly_rates]
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

  describe "#all_total_sums" do
    it "is a hash of all summable columns" do
      expect(query_results.all_total_sums)
        .to eql(estimated_hours_column => 20.0,
                int_cf_column => 30,
                float_cf_column => 10.24,
                material_costs_column => 400.0,
                labor_costs_column => 600.0,
                overall_costs_column => 1000.0,
                remaining_hours_column => 14.0,
                story_points_column => 21)
    end

    context "when filtering" do
      before do
        query.add_filter("assigned_to_id", "=", [current_user.id.to_s])
      end

      it "is a hash of all summable columns and includes only the work packages matching the filter" do
        expect(query_results.all_total_sums)
          .to eql(estimated_hours_column => 10.0,
                  int_cf_column => 20,
                  float_cf_column => 6.83,
                  material_costs_column => 200.0,
                  labor_costs_column => 300.0,
                  overall_costs_column => 500.0,
                  remaining_hours_column => 5.0,
                  story_points_column => 14)
      end
    end
  end

  describe "#all_sums_for_group" do
    context "when grouped by assigned_to" do
      let(:group_by) { :assigned_to }

      it "is a hash of sums grouped by user values (and nil) and grouped columns" do
        expect(query_results.all_group_sums)
          .to eql(current_user => { estimated_hours_column => 10.0,
                                    int_cf_column => 20,
                                    float_cf_column => 6.83,
                                    material_costs_column => 200.0,
                                    labor_costs_column => 300.0,
                                    overall_costs_column => 500.0,
                                    remaining_hours_column => 5.0,
                                    story_points_column => 14 },
                  nil => { estimated_hours_column => 10.0,
                           int_cf_column => 10,
                           float_cf_column => 3.41,
                           material_costs_column => 200.0,
                           labor_costs_column => 300.0,
                           overall_costs_column => 500.0,
                           remaining_hours_column => 9.0,
                           story_points_column => 7 })
      end

      context "when filtering" do
        before do
          query.add_filter("responsible_id", "=", [current_user.id.to_s])
        end

        it "is a hash of sums grouped by user values and grouped columns" do
          expect(query_results.all_group_sums)
            .to eql(current_user => { estimated_hours_column => 5.0,
                                      int_cf_column => 10,
                                      float_cf_column => 3.41,
                                      material_costs_column => 0.0,
                                      labor_costs_column => 0.0,
                                      overall_costs_column => 0.0,
                                      story_points_column => 7,
                                      remaining_hours_column => 2.5 })
        end
      end
    end

    context "when grouped by done_ratio" do
      let(:group_by) { :done_ratio }

      it "is a hash of sums grouped by done_ratio values and grouped columns" do
        expect(query_results.all_group_sums)
          .to eql(50 => { estimated_hours_column => 10.0,
                          int_cf_column => 20,
                          float_cf_column => 6.83,
                          material_costs_column => 200.0,
                          labor_costs_column => 300.0,
                          overall_costs_column => 500.0,
                          remaining_hours_column => 5.0,
                          story_points_column => 14 },
                  10 => { estimated_hours_column => 10.0,
                          int_cf_column => 10,
                          float_cf_column => 3.41,
                          material_costs_column => 200.0,
                          labor_costs_column => 300.0,
                          overall_costs_column => 500.0,
                          remaining_hours_column => 9.0,
                          story_points_column => 7 })
      end

      context "when filtering" do
        before do
          query.add_filter("responsible_id", "=", [current_user.id.to_s])
        end

        it "is a hash of sums grouped by done_ratio values and grouped columns" do
          expect(query_results.all_group_sums)
            .to eql(50 => { estimated_hours_column => 5.0,
                            int_cf_column => 10,
                            float_cf_column => 3.41,
                            material_costs_column => 0.0,
                            labor_costs_column => 0.0,
                            overall_costs_column => 0.0,
                            story_points_column => 7,
                            remaining_hours_column => 2.5 })
        end
      end
    end
  end
end
