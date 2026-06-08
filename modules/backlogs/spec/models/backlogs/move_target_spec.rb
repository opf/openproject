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

RSpec.describe Backlogs::MoveTarget do
  describe ".for" do
    it "encodes a sprint story" do
      work_package = instance_double(WorkPackage, sprint_id: 42, backlog_bucket_id: nil)
      target = described_class.for(work_package)

      expect(target.list_type).to eq("sprint")
      expect(target.list_id).to eq(42)
    end

    it "encodes a backlog bucket story" do
      work_package = instance_double(WorkPackage, sprint_id: nil, backlog_bucket_id: 99)
      target = described_class.for(work_package)

      expect(target.list_type).to eq("backlog_bucket")
      expect(target.list_id).to eq(99)
    end

    it "encodes an inbox story" do
      work_package = instance_double(WorkPackage, sprint_id: nil, backlog_bucket_id: nil)
      target = described_class.for(work_package)

      expect(target.list_type).to eq("inbox")
      expect(target.list_id).to be_nil
    end

    it "treats a bucket assignment as a bucket even when a sprint is also set" do
      work_package = instance_double(WorkPackage, sprint_id: 42, backlog_bucket_id: 99)
      target = described_class.for(work_package)

      expect(target.list_type).to eq("backlog_bucket")
      expect(target.list_id).to eq(99)
      expect(target.attributes).to eq(backlog_bucket_id: 99, sprint_id: nil)
    end
  end

  describe ".from_list" do
    it "decodes a sprint with a string id" do
      expect(described_class.from_list("sprint", "42").attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: "42")
    end

    it "normalizes an integer sprint id before validating" do
      expect(described_class.from_list("sprint", 42).attributes)
        .to eq(backlog_bucket_id: nil, sprint_id: "42")
    end

    it "decodes a backlog bucket" do
      expect(described_class.from_list("backlog_bucket", "99").attributes)
        .to eq(backlog_bucket_id: "99", sprint_id: nil)
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
