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

RSpec.describe Calendar::CreateVtodoService, type: :model do
  let(:project) { create(:project) }
  let(:query_name) { "Tasks" }
  let(:dates) { nil }
  let(:instance) { described_class.new }

  subject(:result) do
    instance.call(work_packages:, calendar_name: query_name, dates:)
  end

  let(:unfolded_result) { result.result.gsub("\r\n ", "").delete("\r") }

  describe "work package dates" do
    context "with a start and due date" do
      let(:work_package) do
        create(:work_package, project:,
                              start_date: Date.new(2026, 1, 5),
                              due_date: Date.new(2026, 1, 10))
      end
      let(:work_packages) { [work_package] }

      it "emits a VTODO with DTSTART and DUE" do
        expect(unfolded_result).to include("BEGIN:VTODO")
        expect(unfolded_result).not_to include("BEGIN:VEVENT")
        expect(unfolded_result).to include("DTSTART;VALUE=DATE:20260105")
        expect(unfolded_result).to include("DUE;VALUE=DATE:20260110")
        expect(unfolded_result).not_to include("DTEND")
      end

      context "when dates=due" do
        let(:dates) { "due" }

        it "emits only the due date" do
          expect(unfolded_result).not_to include("DTSTART")
          expect(unfolded_result).to include("DUE;VALUE=DATE:20260110")
        end
      end
    end

    context "with only a due date" do
      let(:work_package) do
        create(:work_package, project:, due_date: Date.new(2026, 2, 3))
      end
      let(:work_packages) { [work_package] }

      it "emits only DUE" do
        expect(unfolded_result).to include("DUE;VALUE=DATE:20260203")
        expect(unfolded_result).not_to include("DTSTART")
      end
    end

    context "with only a start date" do
      let(:work_package) do
        create(:work_package, project:, start_date: Date.new(2026, 3, 4))
      end
      let(:work_packages) { [work_package] }

      it "emits only DTSTART" do
        expect(unfolded_result).to include("DTSTART;VALUE=DATE:20260304")
        expect(unfolded_result).not_to include("DUE")
      end
    end
  end

  describe "status mapping" do
    let(:status) { create(:status) }
    let(:work_package) do
      create(:work_package, project:,
                            start_date: Date.new(2026, 1, 5),
                            due_date: Date.new(2026, 1, 10),
                            status:)
    end
    let(:work_packages) { [work_package] }

    context "with a closed status" do
      let(:status) { create(:closed_status) }

      it { expect(unfolded_result).to include("STATUS:COMPLETED") }
    end

    context "with an in-progress status" do
      let(:status) { create(:in_progress_status) }

      it { expect(unfolded_result).to include("STATUS:IN-PROCESS") }
    end

    context "with a rejected status" do
      let(:status) { create(:rejected_status) }

      it { expect(unfolded_result).to include("STATUS:CANCELLED") }
    end

    context "with an ordinary status" do
      it { expect(unfolded_result).to include("STATUS:NEEDS-ACTION") }
    end
  end

  describe "priority mapping" do
    let(:priority) { create(:priority_high) }
    let(:work_package) do
      create(:work_package, project:,
                            due_date: Date.new(2026, 1, 10),
                            priority:)
    end
    let(:work_packages) { [work_package] }

    it { expect(unfolded_result).to include("PRIORITY:3") }
  end

  describe "calendar metadata" do
    let(:work_packages) { [create(:work_package, project:, due_date: Date.new(2026, 1, 10))] }

    it "keeps the calendar name and refresh interval" do
      expect(unfolded_result).to include("X-WR-CALNAME:#{query_name}")
      expect(unfolded_result).to include("REFRESH-INTERVAL;VALUE=DURATION:PT1H")
    end
  end
end
