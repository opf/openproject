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
        type: :sprint,
        to_s: "sprint:42",
        to_h: { type: :sprint, id: 42 },
        to_filter: { name: "sprint", operator: "!", values: [42] },
        to_container_params: { sprint_id: 42 }
      )
    end
  end

  describe "BucketId" do
    subject { described_class::BucketId[13] }

    it do
      expect(subject).to have_attributes(
        id: 13,
        type: :backlog_bucket,
        to_s: "backlog_bucket:13",
        to_h: { type: :backlog_bucket, id: 13 },
        to_filter: { name: "backlogBucket", operator: "!", values: [13] },
        to_container_params: { backlog_bucket_id: 13 }
      )
    end
  end

  describe "InboxId" do
    subject { described_class::InboxId }

    it do
      expect(subject).to have_attributes(
        type: :inbox,
        to_s: "inbox",
        to_h: { type: :inbox },
        to_filter: { name: "backlogInbox", operator: "=", values: [OpenProject::Database::DB_VALUE_FALSE] },
        to_container_params: {}
      )
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

  describe ".parse" do
    it "parses a sprint target" do
      expect(described_class.parse("sprint:4")).to eq(described_class::SprintId[4])
    end

    it "parses a backlog_bucket target" do
      expect(described_class.parse("backlog_bucket:3")).to eq(described_class::BucketId[3])
    end

    it "parses inbox" do
      expect(described_class.parse("inbox")).to eq(described_class::InboxId)
    end

    it "returns nil for an unknown type" do
      expect(described_class.parse("unknown:1")).to be_nil
    end

    it "returns nil for a non-numeric sprint id" do
      expect(described_class.parse("sprint:abc")).to be_nil
    end

    it "returns nil for a non-numeric backlog_bucket id" do
      expect(described_class.parse("backlog_bucket:abc")).to be_nil
    end

    it "returns nil for an empty string" do
      expect(described_class.parse("")).to be_nil
    end
  end

  describe "round-trip serialisation" do
    [
      described_class::SprintId[1],
      described_class::BucketId[2],
      described_class::InboxId
    ].each do |target|
      it "round-trips #{target}" do
        expect(described_class.parse(target.to_s)).to eq(target)
      end
    end
  end
end
