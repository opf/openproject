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

RSpec.describe Import::JiraImportJournals, "integration" do
  subject(:service) { described_class.new(work_package:) }

  let(:work_package) { create(:work_package) }
  let(:commenter) { create(:user) }

  def history_entry(created:, author: "Alice", items: [])
    {
      "created" => created,
      "author" => { "displayName" => author },
      "items" => items
    }
  end

  describe "#update_creation_entry" do
    let(:import_date) { "2022-03-15T10:00:00.000+0000" }

    it "updates created_at, updated_at and validity_period of the first journal" do
      service.update_creation_entry(date_time: import_date)

      journal = work_package.journals.reload.first
      expected_time = Time.zone.parse(import_date)

      expect(journal.created_at).to be_within(1.second).of(expected_time)
      expect(journal.updated_at).to be_within(1.second).of(expected_time)
      expect(journal.validity_period.begin).to be_within(1.second).of(expected_time)
    end

    it "does not create extra journals" do
      expect { service.update_creation_entry(date_time: import_date) }
        .not_to change { work_package.journals.reload.count }
    end
  end

  describe "#call" do
    context "with a single history entry" do
      let(:history_items) do
        [{ "field" => "status", "fromString" => "Open", "toString" => "In Progress" }]
      end

      before do
        service.add_history(history: [history_entry(created: "2022-03-15T11:00:00.000+0000", items: history_items)])
        service.call
      end

      it "creates one additional journal" do
        expect(work_package.journals.reload.count).to eq(2)
      end

      it "saves the journal with cause_type 'import'" do
        journal = work_package.journals.reload.last
        expect(journal.cause_type).to eq("import")
      end

      it "stores the history items in the journal cause" do
        journal = work_package.journals.reload.last
        import_history = journal.cause_import_history
        expect(import_history).to be_present
        expect(import_history.first["author_name"]).to eq("Alice")
        expect(import_history.first["items"].first["field"]).to eq("status")
      end

      it "persists a valid journal (passes DB uniqueness constraint on version)" do
        expect(work_package.journals.reload.map(&:version).sort).to eq([1, 2])
      end
    end

    context "with a single comment" do
      before do
        service.add_comment(
          comment: { "created" => "2022-03-15T12:00:00.000+0000", "body" => "A plain comment." },
          user: commenter
        )
        service.call
      end

      it "creates one additional journal" do
        expect(work_package.journals.reload.count).to eq(2)
      end

      it "stores the comment notes on the journal" do
        journal = work_package.journals.reload.last
        expect(journal.notes).to eq("A plain comment.")
      end

      it "assigns the comment author to the journal" do
        journal = work_package.journals.reload.last
        expect(journal.user).to eq(commenter)
      end

      it "does not set a cause_type on comment journals" do
        journal = work_package.journals.reload.last
        expect(journal.cause_type).to be_blank
      end
    end

    context "with Jira wiki markup in a comment" do
      before do
        service.add_comment(
          comment: { "created" => "2022-03-15T12:00:00.000+0000", "body" => "This is *bold* text." },
          user: commenter
        )
        service.call
      end

      it "converts markup to Markdown in the notes" do
        journal = work_package.journals.reload.last
        expect(journal.notes).to eq("This is **bold** text.")
      end
    end

    context "with multiple entries" do
      let(:comment_time)  { "2022-03-15T11:30:00.000+0000" }
      let(:history_time)  { "2022-03-15T11:00:00.000+0000" }
      let(:history_time2) { "2022-03-15T12:00:00.000+0000" }

      before do
        service.add_history(history: [history_entry(created: history_time)])
        service.add_comment(
          comment: { "created" => comment_time, "body" => "comment" },
          user: commenter
        )
        service.add_history(history: [history_entry(created: history_time2)])
        service.call
      end

      it "creates three additional journals (one per entry)" do
        expect(work_package.journals.reload.count).to eq(4)
      end

      it "stores journals in ascending version order" do
        versions = work_package.journals.reload.map(&:version).sort
        expect(versions).to eq([1, 2, 3, 4])
      end

      it "processes entries in chronological order regardless of add order" do
        journals = work_package.journals.reload.order(:version)
        # version 1 = initial creation
        # version 2 = history_time (earliest)
        # version 3 = comment_time
        # version 4 = history_time2 (latest)
        expect(journals[1].cause_type).to eq("import")
        expect(journals[2].notes).to eq("comment")
        expect(journals[3].cause_type).to eq("import")
      end
    end

    context "when history entries from the same author within the same minute are grouped" do
      let(:time1) { "2022-03-15T11:00:10.000+0000" }
      let(:time2) { "2022-03-15T11:00:50.000+0000" }
      let(:items1) { [{ "field" => "assignee", "fromString" => nil, "toString" => "Bob" }] }
      let(:items2) { [{ "field" => "priority", "fromString" => "Low", "toString" => "High" }] }

      before do
        service.add_history(history: [
                              history_entry(created: time1, author: "Alice", items: items1),
                              history_entry(created: time2, author: "Alice", items: items2)
                            ])
        service.call
      end

      it "merges them into a single journal" do
        expect(work_package.journals.reload.count).to eq(2)
      end

      it "stores both items in the merged journal cause" do
        journal = work_package.journals.reload.last
        items = journal.cause_import_history.first["items"]
        expect(items.pluck("field")).to contain_exactly("assignee", "priority")
      end
    end

    context "when history entries from different authors in the same minute are not grouped" do
      let(:time1) { "2022-03-15T11:00:10.000+0000" }
      let(:time2) { "2022-03-15T11:00:50.000+0000" }

      before do
        service.add_history(history: [
                              history_entry(created: time1, author: "Alice"),
                              history_entry(created: time2, author: "Bob")
                            ])
        service.call
      end

      it "creates a separate journal for each author" do
        expect(work_package.journals.reload.count).to eq(3)
      end
    end

    context "when history entries from the same author more than one minute apart are not grouped" do
      let(:time1) { "2022-03-15T11:00:00.000+0000" }
      let(:time2) { "2022-03-15T11:01:30.000+0000" }
      # Items must differ so the cause JSON differs and the DB-level journal aggregation
      # does not merge the two distinct journals into one.
      let(:items1) { [{ "field" => "status", "fromString" => "Open", "toString" => "In Progress" }] }
      let(:items2) { [{ "field" => "priority", "fromString" => "Low", "toString" => "High" }] }

      before do
        service.add_history(history: [
                              history_entry(created: time1, author: "Alice", items: items1),
                              history_entry(created: time2, author: "Alice", items: items2)
                            ])
        service.call
      end

      it "creates a separate journal for each entry" do
        expect(work_package.journals.reload.count).to eq(3)
      end
    end

    context "when two consecutive entries both contain description changes" do
      let(:time1) { "2022-03-15T11:00:10.000+0000" }
      let(:time2) { "2022-03-15T11:00:40.000+0000" }
      let(:desc_item1) { [{ "field" => "description", "fromString" => "old", "toString" => "new1" }] }
      let(:desc_item2) { [{ "field" => "description", "fromString" => "new1", "toString" => "new2" }] }

      before do
        service.add_history(history: [
                              history_entry(created: time1, author: "Alice", items: desc_item1),
                              history_entry(created: time2, author: "Alice", items: desc_item2)
                            ])
        service.call
      end

      it "keeps them as separate journals to avoid merging conflicting description diffs" do
        expect(work_package.journals.reload.count).to eq(3)
      end
    end

    context "when a description item is grouped with a non-description item from same author" do
      let(:time1) { "2022-03-15T11:00:10.000+0000" }
      let(:time2) { "2022-03-15T11:00:40.000+0000" }
      let(:desc_item)   { [{ "field" => "description", "fromString" => "old", "toString" => "new" }] }
      let(:status_item) { [{ "field" => "status", "fromString" => "Open", "toString" => "Closed" }] }

      before do
        service.add_history(history: [
                              history_entry(created: time1, author: "Alice", items: desc_item),
                              history_entry(created: time2, author: "Alice", items: status_item)
                            ])
        service.call
      end

      it "merges them into a single journal" do
        expect(work_package.journals.reload.count).to eq(2)
      end

      it "converts description content via Jira markup converter" do
        journal = work_package.journals.reload.last
        items = journal.cause_import_history.first["items"]
        desc = items.find { it["field"] == "description" }
        expect(desc).to be_present
      end
    end
  end
end
