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

RSpec.describe AI::TextTransforms::Execution,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  let(:run) { create(:ai_text_transform_run) }
  let(:time) { { now: 0.0 } }
  let(:clock) { -> { time[:now] } }
  let(:advance) { ->(seconds) { time[:now] += seconds } }

  def execute(gateway)
    described_class.new(run, gateway:, clock:).call
    run.reload
  end

  def events
    run.events.order(:seq).map { |event| [event.seq, event.kind, event.payload] }
  end

  it "streams deltas in flush windows and completes with the full text" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b c], before_each: -> { advance.call(0.3) })

    execute(gateway)

    expect(run).to be_succeeded
    expect(run.finished_at).to be_present
    expect(events).to eq([
                           [1, "status", { "status" => "running" }],
                           [2, "text_delta", { "delta" => "ab" }],
                           [3, "text_delta", { "delta" => "c" }],
                           [4, "completed", { "text" => "abc" }]
                         ])
    expect(gateway.calls.first[:timeout]).to eq(described_class::BUDGET)
    expect(gateway.calls.first[:user]).to eq(run.input)
    expect(gateway.calls.first[:system]).to eq(run.system_prompt)
  end

  it "ends cancelled without a completed event when cancellation is requested" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b c d],
                                                  before_each: lambda {
                                                    advance.call(0.6)
                                                    run.update_column(:cancel_requested, true)
                                                  })

    execute(gateway)

    expect(run).to be_cancelled
    expect(events.map(&:second)).to eq(%w[status])
  end

  it "fails with timeout when the budget is exceeded" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b], before_each: -> { advance.call(200) })

    execute(gateway)

    expect(run).to be_failed
    expect(events.last[1]).to eq("error")
    expect(events.last[2]).to eq({ "message" => "The AI service did not respond in time.", "reason" => "timeout" })
    expect(run.error_message).to eq("The AI service did not respond in time.")
  end

  {
    AI::TextTransforms::Errors::ConnectionFailed => ["connection_failed", "The AI service could not be reached."],
    AI::TextTransforms::Errors::Upstream => ["upstream_error", "The AI service returned an error."],
    AI::TextTransforms::Errors::NotAvailable => ["not_available", "The AI assistant is not available."]
  }.each do |error_class, (reason, message)|
    it "maps #{error_class.name.demodulize} to #{reason}" do
      execute(AI::TextTransforms::FakeGateway.new(error: error_class.new("upstream detail")))

      expect(run).to be_failed
      expect(events.last[2]).to eq({ "message" => message, "reason" => reason })
      expect(run.error_message).not_to include("upstream detail")
    end
  end

  it "marks the run failed and re-raises unexpected errors" do
    gateway = AI::TextTransforms::FakeGateway.new(error: RuntimeError.new("boom"))

    expect { described_class.new(run, gateway:, clock:).call }.to raise_error(RuntimeError, "boom")
    expect(run.reload).to be_failed
    expect(events.last[2]["reason"]).to eq("upstream_error")
  end

  it "fails with not_available before streaming when the action is unavailable" do
    run.action.update!(active: false)
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a])

    execute(gateway)

    expect(run).to be_failed
    expect(gateway.calls).to be_empty
    expect(events.map(&:second)).to eq(%w[error])
  end

  it "stops silently when the run was deleted meanwhile" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b],
                                                  before_each: lambda {
                                                    advance.call(0.6)
                                                    AI::TextTransformRun.where(id: run.id).delete_all
                                                  })

    expect { described_class.new(run, gateway:, clock:).call }.not_to raise_error
    expect(AI::TextTransformRun.exists?(run.id)).to be(false)
  end
end
