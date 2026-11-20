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

require "spec_helper"
require_module_spec_helper

RSpec.describe Llm::Completions::Request do
  def request(messages: [{ "role" => "user", "content" => "Hi" }], tools: [], system: "")
    described_class.from_params("system" => system, "messages" => messages, "tools" => tools)
  end

  it "accepts a conversation that ends with a user message" do
    expect(request).to be_valid
  end

  it "reads tool calls, tool results and thinking blocks" do
    parsed = request(messages: [
                       { "role" => "user", "content" => "Hi" },
                       { "role" => "assistant", "content" => "",
                         "toolCalls" => [{ "id" => "c1", "name" => "search", "arguments" => { "q" => "x" } }],
                         "thinking" => { "text" => "", "signature" => "sig", "extra" => "dropped" } },
                       { "role" => "tool", "toolCallId" => "c1", "content" => "[]" }
                     ])

    expect(parsed).to be_valid
    expect(parsed.messages[1].tool_calls.first).to have_attributes(id: "c1", name: "search", arguments: { "q" => "x" })
    expect(parsed.messages[1].thinking).to eq("text" => "", "signature" => "sig")
    expect(parsed.messages[2].tool_call_id).to eq("c1")
  end

  it "rejects an empty conversation, an unknown role and a conversation that ends with the assistant" do
    expect(request(messages: [])).not_to be_valid
    expect(request(messages: [{ "role" => "system", "content" => "x" }])).not_to be_valid
    expect(request(messages: [{ "role" => "user", "content" => "Hi" }, { "role" => "assistant", "content" => "Hello" }]))
      .not_to be_valid
  end

  it "rejects a tool result without a tool call id" do
    expect(request(messages: [{ "role" => "tool", "content" => "[]" }])).not_to be_valid
  end

  it "rejects invalid and duplicate tool names" do
    expect(request(tools: [{ "name" => "bad name" }])).not_to be_valid
    expect(request(tools: [{ "name" => "search" }, { "name" => "search" }])).not_to be_valid
    expect(request(tools: [{ "name" => "search" }])).to be_valid
  end

  it "rejects too many messages, too many tools and too much text" do
    expect(request(messages: Array.new(described_class::MAX_MESSAGES + 1) { { "role" => "user", "content" => "x" } }))
      .not_to be_valid
    expect(request(tools: Array.new(described_class::MAX_TOOLS + 1) { |index| { "name" => "tool_#{index}" } }))
      .not_to be_valid
    expect(request(system: "x" * (described_class::MAX_CHARACTERS + 1))).not_to be_valid
  end

  it "gives a default schema to a tool without one" do
    expect(request(tools: [{ "name" => "ping" }]).tools.first.input_schema).to eq("type" => "object", "properties" => {})
  end
end
