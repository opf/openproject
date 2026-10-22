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

RSpec.describe Acts::Journalized::Differ::Association do
  describe "#single_attribute_changes" do
    let(:original) do
      build(:work_package,
            custom_values: [
              build_stubbed(:work_package_custom_value, custom_field_id: nil, value: nil),
              build_stubbed(:work_package_custom_value, custom_field_id: nil, value: ""),
              build_stubbed(:work_package_custom_value, custom_field_id: 1, value: 1),
              build_stubbed(:work_package_custom_value, custom_field_id: 2, value: 2),
              # not for custom_field_id: 3
              build_stubbed(:work_package_custom_value, custom_field_id: 4, value: 4),
              build_stubbed(:work_package_custom_value, custom_field_id: 5, value: ""),
              build_stubbed(:work_package_custom_value, custom_field_id: 6, value: nil),
              build_stubbed(:work_package_custom_value, custom_field_id: 7, value: nil),
              build_stubbed(:work_package_custom_value, custom_field_id: 8, value: 1),
              build_stubbed(:work_package_custom_value, custom_field_id: 8, value: 2),
              build_stubbed(:work_package_custom_value, custom_field_id: 9, value: 1),
              build_stubbed(:work_package_custom_value, custom_field_id: 9, value: 2)
            ])
    end

    let(:changed) do
      build(:work_package,
            custom_values: [
              build_stubbed(:work_package_custom_value, custom_field_id: nil, value: nil),
              build_stubbed(:work_package_custom_value, custom_field_id: nil, value: ""),
              build_stubbed(:work_package_custom_value, custom_field_id: 1, value: 1),
              build_stubbed(:work_package_custom_value, custom_field_id: 2, value: 22),
              build_stubbed(:work_package_custom_value, custom_field_id: 3, value: 3),
              build_stubbed(:work_package_custom_value, custom_field_id: 4, value: ""),
              build_stubbed(:work_package_custom_value, custom_field_id: 5, value: 5),
              build_stubbed(:work_package_custom_value, custom_field_id: 6, value: 6),
              build_stubbed(:work_package_custom_value, custom_field_id: 7, value: ""),
              build_stubbed(:work_package_custom_value, custom_field_id: 8, value: 2),
              build_stubbed(:work_package_custom_value, custom_field_id: 8, value: 1),
              build_stubbed(:work_package_custom_value, custom_field_id: 9, value: 3),
              build_stubbed(:work_package_custom_value, custom_field_id: 9, value: 2)
            ])
    end

    let(:instance) do
      described_class.new(original, changed, association: :custom_values, id_attribute: :custom_field_id, multiple_values:)
    end

    subject(:result) do
      instance.single_attribute_changes(:value, key_prefix: "custom_field")
    end

    describe "requesting all values changes joined" do
      let(:multiple_values) { :joined }

      it "returns the changes" do
        expect(result)
          .to eq(
            "custom_field_2" => ["2", "22"],
            "custom_field_3" => [nil, "3"],
            "custom_field_4" => ["4", ""],
            "custom_field_5" => ["", "5"],
            "custom_field_6" => ["", "6"],
            "custom_field_9" => ["1,2", "2,3"]
          )
      end
    end

    describe "requesting all values changes as array" do
      let(:multiple_values) { true }

      it "returns the changes" do
        expect(result)
          .to eq(
            "custom_field_2" => [["2"], ["22"]],
            "custom_field_3" => [nil, ["3"]],
            "custom_field_4" => [["4"], nil],
            "custom_field_5" => [nil, ["5"]],
            "custom_field_6" => [nil, ["6"]],
            "custom_field_9" => [["1", "2"], ["2", "3"]]
          )
      end
    end

    describe "requesting single value change" do
      let(:multiple_values) { false }

      it "returns the changes" do
        expect(result)
          .to eq(
            "custom_field_2" => ["2", "22"],
            "custom_field_3" => [nil, "3"],
            "custom_field_4" => ["4", nil],
            "custom_field_5" => [nil, "5"],
            "custom_field_6" => [nil, "6"],
            "custom_field_8" => ["1", "2"],
            "custom_field_9" => ["1", "3"]
          )
      end
    end
  end

  describe "#multiple_attributes_changes" do
    let(:original) do
      build(:journal, project_phase_journals: [
              build_stubbed(:project_phase_journal, phase_id: 1, active: false),
              build_stubbed(:project_phase_journal, phase_id: 3, active: true),
              build_stubbed(:project_phase_journal, phase_id: 4, active: true,
                                                    start_date: Date.new(2024, 1, 16),
                                                    finish_date: Date.new(2024, 1, 17))
            ])
    end

    let(:changed) do
      build(:journal, project_phase_journals: [
              build_stubbed(:project_phase_journal, phase_id: 1, active: true),
              build_stubbed(:project_phase_journal, phase_id: 2, active: true),
              build_stubbed(:project_phase_journal, phase_id: 3, active: false,
                                                    start_date: Date.new(2024, 1, 17),
                                                    finish_date: Date.new(2024, 1, 18)),
              build_stubbed(:project_phase_journal, phase_id: 4, active: true,
                                                    start_date: Date.new(2024, 1, 17),
                                                    finish_date: Date.new(2024, 1, 18))
            ])
    end

    let(:instance) do
      described_class.new(original, changed,
                          association: :project_phase_journals,
                          id_attribute: :phase_id,
                          multiple_values:)
    end

    subject(:result) do
      instance.multiple_attributes_changes(
        %i[active start_date finish_date],
        key_prefix: "project_life_cycle_steps"
      )
    end

    describe "requesting joined changes for all values" do
      let(:multiple_values) { :joined }

      it "returns the flat changes" do
        expect(result)
          .to eq(
            "project_life_cycle_steps_1_active" => ["false", "true"],

            "project_life_cycle_steps_2_active" => [nil, "true"],

            "project_life_cycle_steps_3_active" => ["true", "false"],
            "project_life_cycle_steps_3_start_date" => ["", "2024-01-17"],
            "project_life_cycle_steps_3_finish_date" => ["", "2024-01-18"],

            "project_life_cycle_steps_4_start_date" => ["2024-01-16", "2024-01-17"],
            "project_life_cycle_steps_4_finish_date" => ["2024-01-17", "2024-01-18"]
          )
      end
    end

    # this case should not be needed, added for coverting all cases
    describe "requesting all values changes as array" do
      let(:multiple_values) { true }

      it "returns the changes" do
        expect(result)
          .to eq(
            "project_life_cycle_steps_1_active" => [[false], [true]],

            "project_life_cycle_steps_2_active" => [nil, [true]],

            "project_life_cycle_steps_3_active" => [[true], [false]],
            "project_life_cycle_steps_3_start_date" => [nil, [Date.new(2024, 1, 17)]],
            "project_life_cycle_steps_3_finish_date" => [nil, [Date.new(2024, 1, 18)]],

            "project_life_cycle_steps_4_start_date" => [[Date.new(2024, 1, 16)], [Date.new(2024, 1, 17)]],
            "project_life_cycle_steps_4_finish_date" => [[Date.new(2024, 1, 17)], [Date.new(2024, 1, 18)]]
          )
      end
    end

    describe "requesting single value change" do
      let(:multiple_values) { false }

      it "returns the flat changes" do
        expect(result)
          .to eq(
            "project_life_cycle_steps_1_active" => [false, true],

            "project_life_cycle_steps_2_active" => [nil, true],

            "project_life_cycle_steps_3_active" => [true, false],
            "project_life_cycle_steps_3_start_date" => [nil, Date.new(2024, 1, 17)],
            "project_life_cycle_steps_3_finish_date" => [nil, Date.new(2024, 1, 18)],

            "project_life_cycle_steps_4_start_date" => [Date.new(2024, 1, 16), Date.new(2024, 1, 17)],
            "project_life_cycle_steps_4_finish_date" => [Date.new(2024, 1, 17), Date.new(2024, 1, 18)]
          )
      end
    end
  end
end
