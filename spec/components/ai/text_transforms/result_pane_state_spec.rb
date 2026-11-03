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

require "rails_helper"

RSpec.describe AI::TextTransforms::ResultPaneState do
  let(:action) { build(:ai_text_transform_action, label: "Fix grammar") }
  let(:run) { build(:ai_text_transform_run, action:, status:) }
  let(:status) { "running" }
  let(:request_id) { SecureRandom.uuid }
  let(:scope) { "document" }

  subject(:pane) { described_class.new(run:, scope:, request_id:) }

  def add_event(kind, payload, seq:)
    run.events.build(kind:, payload:, seq:)
  end

  describe "#state" do
    {
      "queued" => "generating",
      "running" => "generating",
      "succeeded" => "done",
      "failed" => "failed",
      "cancelled" => "cancelled"
    }.each do |run_status, pane_state|
      context "when the run is #{run_status}" do
        let(:status) { run_status }

        it { expect(pane.state).to eq(pane_state) }
      end
    end

    context "when the run failed because the response was blocked" do
      let(:status) { "failed" }

      before { add_event("error", { "reason" => "blocked", "message" => "Blocked" }, seq: 1) }

      it { expect(pane.state).to eq("stopped") }
    end

    context "when the run failed for another reason" do
      let(:status) { "failed" }

      before { add_event("error", { "reason" => "timeout", "message" => "Too slow" }, seq: 1) }

      it { expect(pane.state).to eq("failed") }
    end

    context "when the start was rejected" do
      subject(:pane) do
        described_class.rejected(message: "Not available", label: "Fix grammar", scope:, request_id:)
      end

      it { expect(pane.state).to eq("failed") }
    end
  end

  describe "#retryable?" do
    %w[queued running succeeded cancelled].each do |run_status|
      context "when the run is #{run_status}" do
        let(:status) { run_status }

        it { is_expected.not_to be_retryable }
      end
    end

    context "when the run failed" do
      let(:status) { "failed" }

      it { is_expected.to be_retryable }
    end

    context "when the start was rejected" do
      subject(:pane) { described_class.rejected(message: "Not available", label: "Fix grammar", scope:, request_id:) }

      it { is_expected.not_to be_retryable }
    end
  end

  describe "#text" do
    before do
      add_event("text_delta", { "delta" => "lo" }, seq: 2)
      add_event("text_delta", { "delta" => "Hel" }, seq: 1)
    end

    it "concatenates the text deltas in sequence order" do
      expect(pane.text).to eq("Hello")
    end

    context "with a completed event" do
      before { add_event("completed", { "text" => "Hello world" }, seq: 3) }

      it "returns the completed text" do
        expect(pane.text).to eq("Hello world")
      end
    end
  end

  describe "without a run" do
    let(:run) { nil }

    it "is failed with a generic message, no text and an empty label" do
      expect(pane.state).to eq("failed")
      expect(pane.error_message).to eq(I18n.t("ai.text_transform.errors.upstream_error"))
      expect(pane.text).to eq("")
      expect(pane.label).to eq("")
    end
  end

  describe "#error_message" do
    let(:status) { "failed" }

    before { run.error_message = "Run failed" }

    it "falls back to the run's error message" do
      expect(pane.error_message).to eq("Run failed")
    end

    context "with an error event" do
      before { add_event("error", { "reason" => "timeout", "message" => "Too slow" }, seq: 1) }

      it "prefers the event's message" do
        expect(pane.error_message).to eq("Too slow")
      end
    end

    context "when the start was rejected" do
      subject(:pane) do
        described_class.rejected(message: "Not available", label: "Fix grammar", scope:, request_id:)
      end

      it { expect(pane.error_message).to eq("Not available") }
    end
  end

  describe "#last_seq" do
    it { expect(pane.last_seq).to eq(0) }

    context "with events" do
      before do
        add_event("status", { "status" => "running" }, seq: 1)
        add_event("text_delta", { "delta" => "Hi" }, seq: 2)
      end

      it { expect(pane.last_seq).to eq(2) }
    end
  end

  describe "#uuid" do
    it { expect(pane.uuid).to eq(run.uuid) }

    context "without a run" do
      let(:run) { nil }

      it { expect(pane.uuid).to eq("rejected") }
    end
  end

  describe "#label" do
    it "uses the action's label" do
      expect(pane.label).to eq("Fix grammar")
    end

    context "with an explicit label" do
      subject(:pane) { described_class.new(run:, scope:, request_id:, label: "Summarize") }

      it { expect(pane.label).to eq("Summarize") }
    end
  end
end
