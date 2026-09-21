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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Import::CSV::RowMapper do
  subject(:mapper) { described_class.new(project:) }

  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:other_type) { create(:type, name: "Bug") }
  shared_let(:project) { create(:project, types: [type, other_type]) }
  shared_let(:status) { create(:status, name: "New") }
  shared_let(:priority) { create(:issue_priority, name: "Normal") }
  shared_let(:category) { create(:category, project:, name: "Backend") }
  shared_let(:assignee) { create(:user, mail: "alice@example.com") }

  def row(values, number: 2, problems: [])
    WorkPackages::Import::CSV::Parser::Row.new(number:, values:, problems:)
  end

  def map(**values)
    mapper.call(row(values))
  end

  def map_row(values, **)
    mapper.call(row(values, **))
  end

  describe "attributes" do
    it "passes text through unchanged" do
      result = map(subject: "  Write the docs  ", description: "Line one")

      expect(result).to be_success
      expect(result.result.attributes).to eq(subject: "  Write the docs  ", description: "Line one")
    end

    it "skips blank cells rather than mapping them to nil" do
      result = map(subject: "Write the docs", description: "", type: nil)

      expect(result.result.attributes).to eq(subject: "Write the docs")
    end

    it "keeps created on and updated on out of the attributes" do
      result = map(subject: "Write the docs",
                   created_at: "2026-01-04T09:00:00Z",
                   updated_at: "2026-01-05T10:30:00Z")

      expect(result.result.attributes).to eq(subject: "Write the docs")
      expect(result.result.timestamps).to eq(created_at: Time.utc(2026, 1, 4, 9),
                                             updated_at: Time.utc(2026, 1, 5, 10, 30))
    end
  end

  describe "lookups" do
    it "resolves type, status, priority and category by name, ignoring case and padding" do
      result = map(type: " task ", status: "NEW", priority: "normal", category: "backend")

      expect(result).to be_success
      expect(result.result.attributes).to eq(type:, status:, priority:, category:)
    end

    it "resolves the assignee by email, ignoring case" do
      result = map(assigned_to: "ALICE@example.com")

      expect(result.result.attributes).to eq(assigned_to: assignee)
    end

    # Beside the message rather than inside it, so the report can fold a long list away while
    # the download still carries all of it.
    it "collects the alternatives when a type is not in the project" do
      result = map(type: "Milestone")

      expect(result).to be_failure
      expect(result.result.map(&:message)).to eq(["does not exist in this project."])
      expect(mapper.available).to eq("type" => ["Task", "Bug"])
    end

    it "reports a status without claiming it is project specific" do
      result = map(status: "Closed")

      expect(result.result.first.message).to eq("does not exist.")
      expect(mapper.available).to eq("status" => ["New"])
    end

    # A list per attribute, not per failing cell: at the problem cap the difference is the bulk
    # of what the run stores.
    it "collects each list once, however many cells fail on it" do
      map_row({ type: "Milestone" }, number: 2)
      first = mapper.available["type"]

      2.times { |n| map_row({ type: "Milestone" }, number: n + 3) }

      expect(mapper.available.keys).to eq(["type"])
      expect(mapper.available["type"]).to equal(first)
    end

    it "collects nothing for an attribute no row failed on" do
      map(type: "Task")

      expect(mapper.available).to be_empty
    end

    it "hands every cell failing on the same attribute one shared message" do
      messages = Array.new(3) { |n| map_row({ type: "Milestone" }, number: n + 2).result.first.message }

      expect(messages.map(&:object_id).uniq.size).to eq(1)
    end

    it "loads a lookup only when a row uses it" do
      allow(Status).to receive(:all).and_call_original

      map(type: "Task")

      expect(Status).not_to have_received(:all)
    end

    it "reports an unknown assignee without listing users" do
      result = map(assigned_to: "nobody@example.com")

      expect(result.result.first.message)
        .to eq("does not match an active user. Use the email address the user signs in with.")
    end

    it "does not accept a locked user" do
      create(:user, mail: "locked@example.com", status: Principal.statuses[:locked])

      expect(map(assigned_to: "locked@example.com")).to be_failure
    end

    describe "#prime" do
      shared_let(:bob) { create(:user, mail: "bob@example.com") }

      let(:rows) do
        [row({ assigned_to: "ALICE@example.com" }),
         row({ assigned_to: " bob@example.com " }),
         row({ assigned_to: "alice@example.com" }),
         row({ assigned_to: "nobody@example.com" }),
         row({ subject: "No assignee" })]
      end

      it "resolves every distinct address in one query" do
        allow(User).to receive(:active).and_call_original

        mapper.prime(rows)

        expect(User).to have_received(:active).once
      end

      it "leaves nothing for the rows themselves to query" do
        mapper.prime(rows)
        allow(User).to receive(:active).and_call_original

        rows.each { |row| mapper.call(row) }

        expect(User).not_to have_received(:active)
      end

      it "still reports an address it could not resolve" do
        mapper.prime(rows)

        result = mapper.call(row({ assigned_to: "nobody@example.com" }))

        expect(result).to be_failure
        expect(result.result.first)
          .to have_attributes(attribute: "assigned_to",
                              value: "nobody@example.com",
                              message: "does not match an active user. " \
                                       "Use the email address the user signs in with.")
      end

      it "resolves the addresses it primed" do
        mapper.prime(rows)

        expect(mapper.call(rows.first).result.attributes).to eq(assigned_to: assignee)
        expect(mapper.call(rows.second).result.attributes).to eq(assigned_to: bob)
      end

      it "asks for nothing when no row names an assignee" do
        allow(User).to receive(:active).and_call_original

        mapper.prime([row({ subject: "No assignee" }), row({ assigned_to: "" })])

        expect(User).not_to have_received(:active)
      end

      it "does not ask again for an address already cached" do
        mapper.call(row({ assigned_to: "alice@example.com" }))
        allow(User).to receive(:active).and_call_original

        mapper.prime([row({ assigned_to: "alice@example.com" })])

        expect(User).not_to have_received(:active)
      end
    end

    it "queries once for an email repeated across rows" do
      allow(User).to receive(:active).and_call_original

      3.times { mapper.call(row({ assigned_to: "alice@example.com" })) }

      expect(User).to have_received(:active).once
    end
  end

  describe "coercion" do
    it "reads dates as ISO 8601" do
      result = map(start_date: "2026-01-05", due_date: "2026-01-09")

      expect(result.result.attributes).to eq(start_date: Date.new(2026, 1, 5),
                                             due_date: Date.new(2026, 1, 9))
    end

    it "rejects a date written the way a spreadsheet exports it" do
      result = map(start_date: "01/05/2026")

      expect(result.result.first.message).to eq("must be a date written as YYYY-MM-DD.")
    end

    it "leaves work to WorkPackage#estimated_hours=, which runs the same converter" do
      expect(map(estimated_hours: "1h30m").result.attributes).to eq(estimated_hours: "1h30m")
      expect(map(estimated_hours: "PT8H").result.attributes).to eq(estimated_hours: "PT8H")
    end

    it "leaves a % complete it cannot read to the numericality validator" do
      expect(map(done_ratio: "half").result.attributes).to eq(done_ratio: "half")
    end

    it "passes a whole % complete through, sign or no sign" do
      expect(map(done_ratio: "50").result.attributes).to eq(done_ratio: "50")
      expect(map(done_ratio: "50%").result.attributes).to eq(done_ratio: "50%")
      expect(map(done_ratio: "99.0").result.attributes).to eq(done_ratio: "99.0")
    end

    it "rejects a fractional % complete, which the integer column would truncate in silence" do
      expect(map(done_ratio: "99.9").result.first.message)
        .to eq("must be a whole number of percent, for example 50.")
      expect(map(done_ratio: "0.4")).to be_failure
    end

    it "rejects a Created on in the future" do
      result = map(created_at: 1.day.from_now.utc.iso8601)

      expect(result.result.sole)
        .to have_attributes(attribute: "created_at", message: "must not be in the future.")
    end

    it "rejects an Updated on in the future" do
      result = map(updated_at: 1.day.from_now.utc.iso8601)

      expect(result.result.sole).to have_attributes(attribute: "updated_at")
    end

    it "rejects a Created on later than the Updated on beside it" do
      result = map(created_at: "2024-05-06T11:15:00Z", updated_at: "2024-03-04T09:30:00Z")

      expect(result.result.sole)
        .to have_attributes(attribute: "created_at",
                            value: "2024-05-06T11:15:00Z",
                            message: "must not be later than the value in Updated on.")
    end

    it "accepts a Created on equal to the Updated on beside it" do
      result = map(created_at: "2024-03-04T09:30:00Z", updated_at: "2024-03-04T09:30:00Z")

      expect(result).to be_success
    end

    it "says nothing about the order when one of the two could not be read" do
      result = map(created_at: "2024-05-06T11:15:00Z", updated_at: "last Tuesday")

      expect(result.result.map(&:message)).to eq(["must be a date and time written as YYYY-MM-DDTHH:MM:SSZ."])
    end

    it "rejects a timestamp that is not ISO 8601" do
      result = map(created_at: "2026-01-04 09:00")

      expect(result.result.first.message)
        .to eq("must be a date and time written as YYYY-MM-DDTHH:MM:SSZ.")
    end
  end

  describe "problems" do
    it "carries the row number, the attribute caption and the value" do
      problem = map_row({ type: "Milestone" }, number: 7).result.first

      expect(problem).to have_attributes(row: 7, attribute: "type", value: "Milestone")
    end

    it "collects every bad cell instead of stopping at the first" do
      result = map(type: "Milestone", status: "Closed", start_date: "yesterday")

      expect(result.result.map(&:attribute)).to eq(%w[type status start_date])
    end

    it "keeps the problems the parser already found and leaves them unattributed" do
      result = map_row({ subject: "Write the docs" }, problems: ["has 4 cells but the header has 3."])

      expect(result).to be_failure
      expect(result.result.first).to have_attributes(row: 2,
                                                     attribute: nil,
                                                     value: nil,
                                                     message: "has 4 cells but the header has 3.")
    end

    it "reports nothing the contract reports better" do
      expect(map(subject: "")).to be_success
    end
  end
end
