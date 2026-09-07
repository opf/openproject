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
  end

  it "sends the stored prompt, the input and the budget to the gateway" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a])

    execute(gateway)

    expect(gateway.calls).to eq([{ system: run.system_prompt, user: run.input, timeout: described_class::BUDGET }])
  end

  it "ends cancelled with only the status event when cancellation is requested between flushes" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b c d],
                                                  before_each: lambda {
                                                    advance.call(0.6)
                                                    run.update_column(:cancel_requested, true)
                                                  })

    execute(gateway)

    expect(run).to be_cancelled
    expect(run.finished_at).to be_present
    expect(events).to eq([[1, "status", { "status" => "running" }]])
  end

  it "stops silently when the run was deleted mid-stream" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b],
                                                  before_each: lambda {
                                                    advance.call(0.6)
                                                    AI::TextTransformRun.where(id: run.id).delete_all
                                                  })

    expect { described_class.new(run, gateway:, clock:).call }.not_to raise_error
    expect(AI::TextTransformRun.exists?(run.id)).to be(false)
  end

  it "fails with timeout when the budget is exceeded" do
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a b], before_each: -> { advance.call(200) })

    execute(gateway)

    expect(run).to be_failed
    expect(events.last[1..]).to eq(["error", { "message" => "The AI service did not respond in time.", "reason" => "timeout" }])
    expect(run.error_message).to eq("The AI service did not respond in time.")
  end

  {
    AI::TextTransforms::Errors::NotAvailable => ["not_available", "The AI assistant is not available."],
    AI::TextTransforms::Errors::ConnectionFailed => ["connection_failed", "The AI service could not be reached."],
    AI::TextTransforms::Errors::TimedOut => ["timeout", "The AI service did not respond in time."],
    AI::TextTransforms::Errors::Upstream => ["upstream_error", "The AI service returned an error."]
  }.each do |error_class, (reason, message)|
    it "maps #{error_class.name.demodulize} to #{reason} without the upstream text" do
      execute(AI::TextTransforms::FakeGateway.new(error: error_class.new("upstream detail")))

      expect(run).to be_failed
      expect(events.last[1..]).to eq(["error", { "message" => message, "reason" => reason }])
      expect(run.error_message).to eq(message)
    end
  end

  it "translates the error message into the language of the run's user" do
    run.user.update!(language: "de")
    I18n.backend.store_translations(:de, ai: { text_transform: { errors: { upstream_error: "KI-Fehler" } } })

    execute(AI::TextTransforms::FakeGateway.new(error: AI::TextTransforms::Errors::Upstream.new("detail")))

    expect(run.error_message).to eq("KI-Fehler")
    expect(I18n.locale).to eq(:en)
  end

  it "marks the run failed with upstream_error and re-raises unexpected errors" do
    gateway = AI::TextTransforms::FakeGateway.new(error: RuntimeError.new("boom"))

    expect { described_class.new(run, gateway:, clock:).call }.to raise_error(RuntimeError, "boom")
    expect(run.reload).to be_failed
    expect(events.last[1..]).to eq(["error", { "message" => "The AI service returned an error.", "reason" => "upstream_error" }])
  end

  it "fails with not_available before streaming when the action is inactive" do
    run.action.update!(active: false)
    gateway = AI::TextTransforms::FakeGateway.new(deltas: %w[a])

    execute(gateway)

    expect(run).to be_failed
    expect(gateway.calls).to be_empty
    expect(events).to eq([[1, "error", { "message" => "The AI assistant is not available.", "reason" => "not_available" }]])
  end
end
