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

RSpec.describe AI::Assistance::ToolCalls do
  subject(:calls) { described_class.new(llm_call) }

  let(:record) { create(:ai_assistant_chat_message) }
  let(:llm_call) { AI::Assistance::LlmCall.new(record:, log_tag: "spec") }
  let(:events) { record.reload.events.select { it["kind"] == "tool_call" }.pluck("data") }

  it "runs a call and records its name, arguments, time, size and result" do
    expect(calls.run("search", { project_id: 1 }) { "result" }).to eq("result")
    expect(events).to contain_exactly(include("name" => "search", "arguments" => { "project_id" => 1 }, "size" => 6,
                                              "result" => "result"))
    expect(events.first).to have_key("seconds")
  end

  it "answers an identical call with the earlier result, without running it again" do
    runs = 0
    calls.run("search", { b: 2, a: 1 }) { (runs += 1) && "result" }
    second = calls.run("search", { a: 1, b: 2 }) { (runs += 1) && "result" }

    expect(runs).to eq(1)
    expect(second).to eq("#{described_class::REPEATED_TEXT}\nresult")
    expect(events.pluck("repeated")).to eq([nil, true])
  end

  it "refuses every call after a repeated call" do
    2.times { calls.run("search", { a: 1 }) { "result" } }

    expect(calls.run("search", { a: 2 }) { "new" }).to eq(described_class::LIMIT_TEXT)
    expect(events.last).to include("refused" => true)
  end

  it "refuses calls over the soft limit" do
    described_class::SOFT_LIMIT.times { |i| calls.run("search", { page: i }) { "result" } }

    expect(calls.run("search", { page: 99 }) { "result" }).to eq(described_class::LIMIT_TEXT)
    expect(events.last).to include("refused" => true)
  end

  it "raises over the hard limit" do
    described_class::HARD_LIMIT.times { |i| calls.run("search", { page: i }) { "result" } }

    expect { calls.run("search", { page: 99 }) { "result" } }.to raise_error(described_class::Exceeded)
  end

  it "passes the hard limit error through the LLM error translation" do
    expect(Llm::Errors.translate(described_class::Exceeded.new("too many"))).to be_a(described_class::Exceeded)
  end

  it "returns an error text when the tool raises" do
    expect(calls.run("search", {}) { raise ArgumentError, "bad" }).to eq(described_class::ERROR_TEXT)
    expect(events.last).to include("error" => "ArgumentError")
  end
end
