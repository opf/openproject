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

require "rails_helper"

RSpec.describe WorkPackage::ProgressHint, :aggreagate_failures do
  describe "#message" do
    it "returns the translated human message for a progress hint" do
      hint = described_class.new("remaining_hours.derived")
      expect(hint.message).to eq("Derived from Work and % Complete.")

      hint = described_class.new("done_ratio.derived")
      expect(hint.message).to eq("Derived from Work and Remaining work.")
    end

    it "converts parameter values to hours formatted according to setting" do
      hint = described_class.new("remaining_hours.increased_by_delta_like_work", { delta: 2 })
      expect(hint.message).to eq("Increased by 2h, matching the increase in Work.")

      hint = described_class.new("remaining_hours.increased_by_delta_like_work", { delta: 15.5 })
      expect(hint.message).to eq("Increased by 15.5h, matching the increase in Work.")

      hint = described_class.new("remaining_hours.decreased_by_delta_like_work", { delta: -24 })
      expect(hint.message).to eq("Decreased by 24h, matching the reduction in Work.")

      with_settings(duration_format: "days_and_hours") do
        hint = described_class.new("remaining_hours.increased_by_delta_like_work", { delta: 2 })
        expect(hint.message).to eq("Increased by 2h, matching the increase in Work.")

        hint = described_class.new("remaining_hours.increased_by_delta_like_work", { delta: 15.5 })
        expect(hint.message).to eq("Increased by 1d 7.5h, matching the increase in Work.")

        hint = described_class.new("remaining_hours.decreased_by_delta_like_work", { delta: -24 })
        expect(hint.message).to eq("Decreased by 3d, matching the reduction in Work.")
      end
    end

    it "rounds parameter values to 2 decimals" do
      hint = described_class.new("remaining_hours.increased_by_delta_like_work", { delta: 0.995 })
      expect(hint.message).to eq("Increased by 1h, matching the increase in Work.")

      hint = described_class.new("remaining_hours.decreased_by_delta_like_work", { delta: -100.004 })
      expect(hint.message).to eq("Decreased by 100h, matching the reduction in Work.")
    end
  end
end
