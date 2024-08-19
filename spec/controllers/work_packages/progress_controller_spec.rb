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

RSpec.describe WorkPackages::ProgressController,
               with_flag: { percent_complete_edition: true } do
  shared_let(:user) { create(:admin) }
  shared_let(:work_package) { create(:work_package) }

  current_user { user }

  describe "POST /work_packages/:d/progress" do
    let(:params) do
      {
        "work_package_id" => work_package.id,
        "work_package" => {
          "estimated_hours" => "42",
          "remaining_hours" => "4h",
          "done_ratio" => "90",
          "estimated_hours_touched" => "false",
          "remaining_hours_touched" => "false",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "updates the work package progress values with touched values (none touched)" do
      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to be_nil
      expect(work_package.remaining_hours).to be_nil
      expect(work_package.done_ratio).to be_nil
    end

    it "updates the work package progress values with touched values (only work touched)" do
      params["work_package"]["estimated_hours_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to eq(42)
      # when not supplied by the user, the remaining work is set to the same
      # value as work
      expect(work_package.remaining_hours).to eq(42)
      expect(work_package.done_ratio).to eq(0)
    end

    it "updates the work package progress values with touched values (only done_ratio touched)" do
      params["work_package"]["done_ratio_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to be_nil
      expect(work_package.remaining_hours).to be_nil
      expect(work_package.done_ratio).to eq(90)
    end

    it "updates the work package progress values (work and remaining work)" do
      params["work_package"]["estimated_hours_touched"] = "true"
      params["work_package"]["remaining_hours_touched"] = "true"

      patch("update", params:, as: :turbo_stream)
      work_package.reload

      expect(work_package.estimated_hours).to eq(42)
      expect(work_package.remaining_hours).to eq(4)
      expect(work_package.done_ratio).to eq(90)
    end
  end

  # Used on new work package creation form
  describe "POST /work_packages/progress" do
    let(:params) do
      {
        "work_package" => {
          "initial" => {
            "estimated_hours" => "",
            "remaining_hours" => "",
            "done_ratio" => ""
          },
          "estimated_hours" => "4h",
          "remaining_hours" => "3",
          "done_ratio" => "0",
          "estimated_hours_touched" => "true",
          "remaining_hours_touched" => "true",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "sends back the entered and derived progress values" do
      post("create", params:, as: :turbo_stream)

      expect(response.body).to be_json_eql({
        estimatedTime: "PT4H",
        remainingTime: "PT3H",
        percentageDone: 25
      }.to_json)
    end
  end
end
