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

RSpec.describe Import::JiraSprintValueParser do
  let(:jira_10_value) do
    "com.atlassian.greenhopper.service.sprint.Sprint@6a9ad71[activatedDate=2025-12-21T23:23:28.766Z," \
      "autoStartStop=false,completeDate=2026-01-04T22:03:28.766Z,endDate=2026-01-04T23:23:28.766Z,goal=<null>," \
      "id=2,incompleteIssuesDestinationId=<null>,name=Sample Sprint 1,rapidViewId=1,sequence=2," \
      "startDate=2025-12-21T23:23:28.766Z,state=CLOSED,synced=false]"
  end
  let(:jira_8_value) do
    "com.atlassian.greenhopper.service.sprint.Sprint@12cfb226[id=11,rapidViewId=36,state=FUTURE,name=Gap Sprint," \
      "startDate=<null>,endDate=<null>,completeDate=<null>,activatedDate=<null>,sequence=11," \
      "goal=Only reachable by sprint id,autoStartStop=false,synced=false]"
  end
  let(:value_with_separators) do
    "com.atlassian.greenhopper.service.sprint.Sprint@706e8ba6[id=8,rapidViewId=33,state=FUTURE," \
      "name=Cross Sprint B, part=2 [beta],startDate=<null>,endDate=<null>,completeDate=<null>,activatedDate=<null>," \
      "sequence=8,goal=Ship A, B and C=done [phase 1], then review,autoStartStop=false,synced=false]"
  end

  describe ".parse" do
    it "reads the string form of Jira 10" do
      expect(described_class.parse(jira_10_value))
        .to eq(id: "2", state: "closed", complete_date: Time.zone.parse("2026-01-04T22:03:28.766Z"))
    end

    it "reads the string form of Jira 8 with its different key order" do
      expect(described_class.parse(jira_8_value)).to eq(id: "11", state: "future", complete_date: nil)
    end

    it "reads the string form when name and goal contain separators" do
      expect(described_class.parse(value_with_separators)).to eq(id: "8", state: "future", complete_date: nil)
    end

    context "when the goal contains an attribute of its own" do
      it "reads the real id in the key order of Jira 8, where the id comes first" do
        value = "com.atlassian.greenhopper.service.sprint.Sprint@706e8ba6[id=8,rapidViewId=33,state=FUTURE," \
                "name=Sprint B,startDate=<null>,endDate=<null>,completeDate=<null>,activatedDate=<null>,sequence=8," \
                "goal=Ship,id=99,then review,autoStartStop=false,synced=false]"

        expect(described_class.parse(value)).to eq(id: "8", state: "future", complete_date: nil)
      end

      it "reads the real id in the key order of Jira 10, where the goal comes first" do
        value = "com.atlassian.greenhopper.service.sprint.Sprint@6a9ad71[activatedDate=<null>,autoStartStop=false," \
                "completeDate=<null>,endDate=<null>,goal=Ship,id=99,then review,id=8," \
                "incompleteIssuesDestinationId=<null>,name=Sprint B,rapidViewId=653,sequence=8,startDate=<null>," \
                "state=FUTURE,synced=false]"

        expect(described_class.parse(value)).to eq(id: "8", state: "future", complete_date: nil)
      end

      it "reads the real state behind a goal that names one" do
        value = "com.atlassian.greenhopper.service.sprint.Sprint@706e8ba6[id=8,rapidViewId=33,state=CLOSED," \
                "name=Sprint B,startDate=<null>,endDate=<null>,completeDate=2026-01-04T22:03:28.766Z," \
                "activatedDate=<null>,sequence=8,goal=Keep,state=ACTIVE all week,autoStartStop=false,synced=false]"

        expect(described_class.parse(value)).to eq(id: "8", state: "closed",
                                                   complete_date: Time.zone.parse("2026-01-04T22:03:28.766Z"))
      end
    end

    it "reads the JSON object form" do
      value = { "id" => 5, "name" => "Sprint 1", "state" => "ACTIVE", "boardId" => 3, "completeDate" => nil }

      expect(described_class.parse(value)).to eq(id: "5", state: "active", complete_date: nil)
    end

    it "reads the completion date of the JSON object form" do
      value = { "id" => 5, "state" => "closed", "completeDate" => "2026-01-04T22:03:28.766Z" }

      expect(described_class.parse(value)[:complete_date]).to eq(Time.zone.parse("2026-01-04T22:03:28.766Z"))
    end

    it "ignores an unparsable completion date" do
      value = { "id" => 5, "state" => "closed", "completeDate" => "yesterday-ish" }

      expect(described_class.parse(value)[:complete_date]).to be_nil
    end

    [
      nil,
      "",
      "Sample Sprint 1",
      "com.atlassian.greenhopper.service.sprint.Sprint@6a9ad71[name=No id,state=ACTIVE]",
      "com.atlassian.greenhopper.service.sprint.Sprint@6a9ad71[id=<null>,state=ACTIVE]",
      { "name" => "No id" },
      { "id" => "abc" },
      42
    ].each do |value|
      it "returns nil for #{value.inspect}" do
        expect(described_class.parse(value)).to be_nil
      end
    end
  end

  describe ".sprint_ids" do
    it "returns the ids of every value of the field" do
      expect(described_class.sprint_ids([jira_10_value, jira_8_value, { "id" => 5 }])).to eq(%w[2 11 5])
    end

    it "skips unrecognized values" do
      expect(described_class.sprint_ids([jira_10_value, "garbage"])).to eq(%w[2])
    end

    it "returns nothing for an empty field" do
      expect(described_class.sprint_ids(nil)).to eq([])
      expect(described_class.sprint_ids([])).to eq([])
    end
  end

  describe ".current_sprint_id" do
    def closed(id, complete_date) = { "id" => id, "state" => "closed", "completeDate" => complete_date }

    it "takes the open sprint wherever it is listed" do
      value = [closed(1, "2026-01-04T22:03:28.766Z"), { "id" => 2, "state" => "active" }, closed(3, "2026-02-04T10:00:00Z")]

      expect(described_class.current_sprint_id(value)).to eq("2")
    end

    it "takes the closed sprint completed last when no sprint is open" do
      value = [closed(1, "2026-02-04T10:00:00Z"), closed(2, "2026-01-04T22:03:28.766Z")]

      expect(described_class.current_sprint_id(value)).to eq("1")
    end

    it "does not take a sprint without a known state as open" do
      value = [{ "id" => 1, "state" => "unknown" }, closed(2, "2026-01-04T22:03:28.766Z")]

      expect(described_class.current_sprint_id(value)).to eq("2")
    end

    it "reads the string form" do
      expect(described_class.current_sprint_id([jira_10_value, jira_8_value])).to eq("11")
    end

    it "returns nil without a sprint" do
      expect(described_class.current_sprint_id(nil)).to be_nil
      expect(described_class.current_sprint_id(["garbage"])).to be_nil
    end
  end

  describe ".parse_date" do
    it "keeps the date of the offset Jira sends" do
      expect(described_class.parse_date("2026-11-02T09:00:00.000+10:00")).to eq(Date.new(2026, 11, 2))
      expect(described_class.parse_date("2026-11-16T17:00:00.000-08:00")).to eq(Date.new(2026, 11, 16))
      expect(described_class.parse_date("2026-09-01T09:00:00.000Z")).to eq(Date.new(2026, 9, 1))
    end

    it "returns nil for a blank or malformed value" do
      expect(described_class.parse_date(nil)).to be_nil
      expect(described_class.parse_date("2026-13-45T09:00:00.000Z")).to be_nil
      expect(described_class.parse_date("not a date")).to be_nil
    end
  end
end
