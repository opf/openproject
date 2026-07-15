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

RSpec.describe Backlogs::Target do
  describe "Inbox" do
    subject { described_class::Inbox }

    it "has the inbox label as name" do
      expect(subject.name).to eq(I18n.t(:label_inbox))
    end
  end

  describe "SprintId" do
    subject { described_class::SprintId[42] }

    it do
      expect(subject).to have_attributes(
        id: 42,
        list_type: "sprint",
        list_id: 42,
        to_list_params: { list_type: "sprint", list_id: 42 },
        to_filter: { name: "sprint", operator: "!", values: [42] },
        to_container_params: { sprint_id: 42 }
      )
    end

    it "exposes the work package attributes" do
      expect(subject.attributes).to eq(sprint_id: 42, backlog_bucket_id: nil)
    end
  end

  describe "BucketId" do
    subject { described_class::BucketId[13] }

    it do
      expect(subject).to have_attributes(
        id: 13,
        list_type: "backlog_bucket",
        list_id: 13,
        to_list_params: { list_type: "backlog_bucket", list_id: 13 },
        to_filter: { name: "backlogBucket", operator: "!", values: [13] },
        to_container_params: { backlog_bucket_id: 13 }
      )
    end

    it "exposes the work package attributes" do
      expect(subject.attributes).to eq(sprint_id: nil, backlog_bucket_id: 13)
    end
  end

  describe "InboxId" do
    subject { described_class::InboxId }

    it do
      expect(subject).to have_attributes(
        list_type: "inbox",
        list_id: nil,
        to_list_params: { list_type: "inbox" },
        to_filter: { name: "backlogInbox", operator: "=", values: [OpenProject::Database::DB_VALUE_FALSE] },
        to_container_params: {}
      )
    end

    it "exposes the work package attributes" do
      expect(subject.attributes).to eq(sprint_id: nil, backlog_bucket_id: nil)
    end
  end

  describe ".for" do
    it "returns a SprintId for a Sprint model" do
      sprint = build_stubbed(:sprint, id: 10)
      expect(described_class.for(sprint)).to eq(described_class::SprintId[10])
    end

    it "returns a BucketId for a BacklogBucket model" do
      bucket = build_stubbed(:backlog_bucket, id: 5)
      expect(described_class.for(bucket)).to eq(described_class::BucketId[5])
    end

    it "returns InboxId for the Inbox null container" do
      expect(described_class.for(described_class::Inbox)).to eq(described_class::InboxId)
    end

    it "raises for an unrecognised container" do
      expect { described_class.for(Object.new) }.to raise_error(NoMatchingPatternError)
    end
  end

  describe ".for_work_package" do
    it "encodes a sprint story" do
      work_package = instance_double(WorkPackage, sprint_id: 42, backlog_bucket_id: nil)
      target = described_class.for_work_package(work_package)

      expect(target.list_type).to eq("sprint")
      expect(target.list_id).to eq(42)
    end

    it "encodes a backlog bucket story" do
      work_package = instance_double(WorkPackage, sprint_id: nil, backlog_bucket_id: 99)
      target = described_class.for_work_package(work_package)

      expect(target.list_type).to eq("backlog_bucket")
      expect(target.list_id).to eq(99)
    end

    it "encodes an inbox story" do
      work_package = instance_double(WorkPackage, sprint_id: nil, backlog_bucket_id: nil)
      target = described_class.for_work_package(work_package)

      expect(target.list_type).to eq("inbox")
      expect(target.list_id).to be_nil
    end

    it "treats a bucket assignment as a bucket even when a sprint is also set" do
      work_package = instance_double(WorkPackage, sprint_id: 42, backlog_bucket_id: 99)
      target = described_class.for_work_package(work_package)

      expect(target.list_type).to eq("backlog_bucket")
      expect(target.list_id).to eq(99)
      expect(target.attributes).to eq(backlog_bucket_id: 99, sprint_id: nil)
    end
  end

  describe "#container_for" do
    shared_let(:project) { create(:project) }
    shared_let(:sprint) { create(:sprint, project:) }
    shared_let(:bucket) { create(:backlog_bucket, project:) }
    shared_let(:other_project_sprint) { create(:sprint) }

    current_user { create(:admin) }

    it "finds the sprint for a SprintId" do
      expect(described_class::SprintId[sprint.id].container_for(project)).to eq(sprint)
    end

    it "finds the bucket for a BucketId" do
      expect(described_class::BucketId[bucket.id].container_for(project)).to eq(bucket)
    end

    it "returns the Inbox null container for InboxId" do
      expect(described_class::InboxId.container_for(project)).to eq(described_class::Inbox)
    end

    it "returns nil for a sprint of another project" do
      expect(described_class::SprintId[other_project_sprint.id].container_for(project)).to be_nil
    end

    it "returns nil for a nonexistent id" do
      expect(described_class::SprintId[Sprint.maximum(:id).to_i + 1].container_for(project)).to be_nil
    end
  end

  describe ".from_list" do
    it "decodes a sprint with a string id" do
      expect(described_class.from_list("sprint", "42").attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: 42)
    end

    it "normalizes an integer sprint id before validating" do
      expect(described_class.from_list("sprint", 42).attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: 42)
    end

    it "normalizes a symbol list type" do
      expect(described_class.from_list(:sprint, 42).attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: 42)
    end

    it "decodes a backlog bucket" do
      expect(described_class.from_list("backlog_bucket", "99").attributes)
        .to eq(backlog_bucket_id: 99, sprint_id: nil)
    end

    it "decodes the inbox with no id" do
      expect(described_class.from_list("inbox", nil).attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: nil)
    end

    it "decodes the inbox with a blank id" do
      expect(described_class.from_list("inbox", "").attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: nil)
    end

    it "rejects an unknown list type" do
      expect(described_class.from_list("unknown", "42")).to be_nil
    end

    it "rejects a sprint without an id" do
      expect(described_class.from_list("sprint", nil)).to be_nil
    end

    it "rejects a sprint with a blank id" do
      expect(described_class.from_list("sprint", "")).to be_nil
    end

    it "rejects a sprint with a non-numeric id" do
      expect(described_class.from_list("sprint", "unknown")).to be_nil
    end

    it "rejects the inbox with an id" do
      expect(described_class.from_list("inbox", "1")).to be_nil
    end
  end
end
