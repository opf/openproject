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

RSpec.describe WorkPackage do
  describe "associations" do
    it { is_expected.to belong_to(:backlog_bucket).class_name("BacklogBucket").optional(true) }
    it { is_expected.to belong_to(:sprint).class_name("Sprint").optional(true) }
  end

  describe "validations" do
    let(:work_package) do
      build(:work_package)
    end

    describe "story points" do
      before do
        work_package.project.enabled_module_names += ["backlogs"]
      end

      it "allows empty values" do
        expect(work_package.story_points).to be_nil
        expect(work_package).to be_valid
      end

      it "allows values greater than or equal to 0" do
        work_package.story_points = "0"
        expect(work_package).to be_valid

        work_package.story_points = "1"
        expect(work_package).to be_valid
      end

      it "allows values less than 10.000" do
        work_package.story_points = "9999"
        expect(work_package).to be_valid
      end

      it "disallows negative values" do
        work_package.story_points = "-1"
        expect(work_package).not_to be_valid
      end

      it "disallows greater or equal than 10.000" do
        work_package.story_points = "10000"
        expect(work_package).not_to be_valid

        work_package.story_points = "10001"
        expect(work_package).not_to be_valid
      end

      it "disallows string values, that are not numbers" do
        work_package.story_points = "abc"
        expect(work_package).not_to be_valid
      end

      it "disallows non-integers" do
        work_package.story_points = "1.3"
        expect(work_package).not_to be_valid
      end
    end
  end

  describe "#backlogs_enabled?" do
    let(:project) { build(:project) }
    let(:work_package) { build(:work_package) }

    it "is false without a project" do
      work_package.project = nil
      expect(work_package).not_to be_backlogs_enabled
    end

    it "is true with a project having the backlogs module" do
      project.enabled_module_names = project.enabled_module_names + ["backlogs"]
      work_package.project = project

      expect(work_package).to be_backlogs_enabled
    end

    it "is false with a project not having the backlogs module" do
      work_package.project = project
      work_package.project.enabled_module_names = nil

      expect(work_package).not_to be_backlogs_enabled
    end
  end

  describe ".order_by_position" do
    let(:work_packages) { create_list(:work_package, 3) }

    it "sorts by position ascending and places NULL positions last" do
      work_packages.each_with_index do |wp, idx|
        position = idx == 0 ? nil : idx
        wp.update_columns(position:)
      end

      ordered_positions = described_class
                      .where(id: work_packages.map(&:id))
                      .order_by_position
                      .pluck(:position)
      expect(ordered_positions).to eq([1, 2, nil])
    end
  end
end
