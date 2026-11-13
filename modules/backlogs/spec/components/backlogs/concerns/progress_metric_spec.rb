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

RSpec.describe Backlogs::Concerns::ProgressMetric do
  let(:project) { build_stubbed(:project) }
  let(:component) do
    Struct.new(:project, :resolved_value, :total_value) do
      include Backlogs::Concerns::ProgressMetric
    end
  end

  def percentage(resolved:, total:)
    component.new(project:, resolved_value: resolved, total_value: total).resolved_percentage
  end

  describe "#resolved_percentage" do
    it "is 0 when there is nothing to resolve" do
      expect(percentage(resolved: 0, total: 0)).to eq(0)
    end

    it "is 0 when nothing is resolved" do
      expect(percentage(resolved: 0, total: 200)).to eq(0)
    end

    it "shows at least 1% once anything is resolved" do
      expect(percentage(resolved: 1, total: 200)).to eq(1)
    end

    it "rounds down so an unfinished epic never shows 100%" do
      expect(percentage(resolved: 199, total: 200)).to eq(99)
    end

    it "is not thrown off by floating point imprecision" do
      expect(percentage(resolved: 29, total: 100)).to eq(29)
    end

    it "is 100 when everything is resolved" do
      expect(percentage(resolved: 200, total: 200)).to eq(100)
    end

    context "when the project's estimation unit is time", with_flag: { project_settings_estimation_unit: true } do
      before { project.estimation_unit = "time" }

      it "rounds down on whole minutes" do
        expect(percentage(resolved: 1.25, total: 7.5)).to eq(16)
      end

      it "fixes floating point imprecision" do
        expect(percentage(resolved: 1.15, total: 1.25)).to eq(92)
      end
    end
  end
end
