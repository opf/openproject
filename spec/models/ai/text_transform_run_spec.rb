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

RSpec.describe AI::TextTransformRun do
  subject(:run) { build(:ai_text_transform_run) }

  it { is_expected.to validate_presence_of(:system_prompt) }
  it { is_expected.to validate_presence_of(:input) }
  it { is_expected.to validate_length_of(:input).is_at_most(AI::TextTransformRun::MAX_INPUT_LENGTH) }

  it "defaults to queued with a generated uuid" do
    expect(run.status).to eq("queued")
    expect(run.uuid).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  it "rejects an unknown status" do
    run.status = "bogus"
    expect(run).not_to be_valid
  end

  describe "#append_event and #events_after" do
    let(:run) { create(:ai_text_transform_run) }

    it "assigns consecutive sequence numbers" do
      seqs = Array.new(3) { |i| run.append_event("text_delta", delta: i.to_s).seq }
      expect(seqs).to eq([1, 2, 3])
    end

    it "rejects a duplicate sequence number at the database level" do
      run.append_event("status", status: "running")
      duplicate = { run_id: run.id, seq: 1, kind: "status", payload: {}, created_at: Time.current }
      expect { AI::TextTransformRunEvent.insert!(duplicate) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "returns only newer events in order" do
      3.times { |i| run.append_event("text_delta", delta: i.to_s) }
      expect(run.events_after(1).map(&:seq)).to eq([2, 3])
      expect(run.events_after(3)).to be_empty
    end
  end

  describe "#start! and #finish!" do
    let(:run) { create(:ai_text_transform_run) }

    it "moves through running to a terminal state" do
      run.start!
      expect(run).to be_running

      run.finish!("failed", error_message: "boom")
      expect(run).to be_failed
      expect(run).to be_terminal
      expect(run.error_message).to eq("boom")
      expect(run.finished_at).to be_present
    end

    it "refuses a non-terminal status" do
      expect { run.finish!("running") }.to raise_error(ArgumentError)
    end
  end

  describe ".expired" do
    let(:retention) { 10.minutes }

    it "selects finished runs past retention and stuck runs older than retention" do
      old_finished = create(:ai_text_transform_run, :succeeded, finished_at: 11.minutes.ago)
      fresh_finished = create(:ai_text_transform_run, :succeeded, finished_at: 1.minute.ago)
      stuck = create(:ai_text_transform_run, :running, created_at: 11.minutes.ago)
      young = create(:ai_text_transform_run, :running, created_at: 1.minute.ago)

      expect(described_class.expired(retention)).to contain_exactly(old_finished, stuck)
      expect(described_class.expired(retention)).not_to include(fresh_finished, young)
    end
  end

  it "deletes its events with the run" do
    run = create(:ai_text_transform_run)
    run.append_event("status", status: "running")

    expect { run.destroy! }.to change(AI::TextTransformRunEvent, :count).by(-1)
  end
end
