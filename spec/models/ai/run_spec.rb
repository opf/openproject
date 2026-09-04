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

RSpec.describe AI::Run do
  subject(:run) { build(:ai_run) }

  it { is_expected.to validate_presence_of(:input) }
  it { is_expected.to validate_length_of(:input).is_at_most(described_class::MAX_INPUT_LENGTH) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }

  describe "status" do
    it "defaults to queued" do
      expect(described_class.new.status).to eq("queued")
    end

    it "allows only the defined values" do
      expect(described_class.statuses.keys)
        .to contain_exactly("queued", "running", "succeeded", "failed", "cancelled")
    end

    it "adds a validation error for unknown values" do
      run.status = "exploded"

      expect(run).not_to be_valid
      expect(run.errors[:status]).to be_present
    end
  end

  describe "uuid" do
    it "is generated on build" do
      expect(run.uuid).to be_present
      expect(build(:ai_run).uuid).not_to eq(run.uuid)
    end

    it "is unique" do
      existing = create(:ai_run)

      expect { create(:ai_run, uuid: existing.uuid) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "context" do
    it "is valid with a work package alone" do
      expect(build(:ai_run)).to be_valid
    end

    it "is valid with a project and a type" do
      expect(build(:ai_run, :for_new_work_package)).to be_valid
    end

    it "is invalid with a project but no type" do
      run = build(:ai_run, :for_new_work_package, type: nil)

      expect(run).not_to be_valid
      expect(run.errors[:work_package]).to be_present
    end

    it "is invalid without work package, project and type" do
      run = build(:ai_run, work_package: nil)

      expect(run).not_to be_valid
      expect(run.errors[:work_package]).to be_present
    end
  end

  describe "#append_event" do
    subject(:run) { create(:ai_run) }

    it "assigns consecutive sequence numbers" do
      events = Array.new(3) { run.append_event("text_delta", { "delta" => "x" }) }

      expect(events.map(&:seq)).to eq([1, 2, 3])
      expect(events).to all(be_persisted)
      expect(events.first.payload).to eq({ "delta" => "x" })
    end

    it "rejects a duplicate sequence number through the unique index" do
      run.append_event("text_delta")

      duplicate = run.events.build(kind: "text_delta", seq: 1)

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#events_after" do
    subject(:run) { create(:ai_run) }

    it "returns the events after the given sequence number in order" do
      run.append_event("text_delta")
      second = run.append_event("text_delta")
      third = run.append_event("completed")

      expect(run.events_after(1)).to eq([second, third])
      expect(run.events_after(3)).to be_empty
    end
  end

  describe "#start!" do
    subject(:run) { create(:ai_run) }

    it "sets the status to running" do
      run.start!

      expect(run.reload).to be_running
      expect(run.finished_at).to be_nil
    end
  end

  describe "#finish!" do
    subject(:run) { create(:ai_run, :running) }

    it "sets a terminal status and the finished_at timestamp" do
      run.finish!("succeeded")

      expect(run.reload).to be_succeeded
      expect(run.finished_at).to be_within(5.seconds).of(Time.current)
      expect(run.error_message).to be_nil
    end

    it "stores the error message" do
      run.finish!("failed", error_message: "boom")

      expect(run.reload).to be_failed
      expect(run.error_message).to eq("boom")
      expect(run.finished_at).to be_present
    end

    it "rejects non-terminal statuses" do
      expect { run.finish!("running") }.to raise_error(ArgumentError, /not a terminal status/)
      expect(run.reload).to be_running
    end
  end

  describe "#terminal?" do
    it "is false for queued and running" do
      expect(build(:ai_run)).not_to be_terminal
      expect(build(:ai_run, :running)).not_to be_terminal
    end

    it "is true for succeeded, failed and cancelled" do
      expect(build(:ai_run, :succeeded)).to be_terminal
      expect(build(:ai_run, :failed)).to be_terminal
      expect(build(:ai_run, :cancelled)).to be_terminal
    end
  end

  describe ".expired" do
    let(:retention) { 5.minutes }

    it "includes runs finished before the retention period" do
      expired = create(:ai_run, :succeeded, finished_at: 10.minutes.ago)
      create(:ai_run, :succeeded, finished_at: Time.current)

      expect(described_class.expired(retention)).to contain_exactly(expired)
    end

    it "includes unfinished runs created before the retention period" do
      stale = create(:ai_run, :running, created_at: 10.minutes.ago)
      create(:ai_run, :running, created_at: Time.current)

      expect(described_class.expired(retention)).to contain_exactly(stale)
    end
  end

  describe "#destroy" do
    it "deletes the events of the run" do
      run = create(:ai_run)
      run.append_event("text_delta")
      run.append_event("completed")

      expect { run.destroy! }.to change(AI::RunEvent, :count).from(2).to(0)
    end
  end
end
