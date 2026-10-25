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

require "rails_helper" require_module_spec_helper

RSpec.describe AI::Assistance::RunEventsComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(events:)) }

  let(:events) do
    [
      { "at" => Time.current.iso8601, "kind" => "tool_call",
        "data" => { "name" => "search_work_packages", "arguments" => { "project_id" => 1 }, "seconds" => 0.2, "size" => 12,
                    "result" => %({"total":12}) } },
      { "at" => Time.current.iso8601, "kind" => "thought", "data" => { "text" => "Counting once more." } },
      { "at" => Time.current.iso8601, "kind" => "tool_call",
        "data" => { "name" => "search_work_packages", "arguments" => { "project_id" => 1 }, "repeated" => true } },
      { "at" => Time.current.iso8601, "kind" => "tool_call",
        "data" => { "name" => "search_work_packages", "arguments" => {}, "refused" => true } },
      { "at" => Time.current.iso8601, "kind" => "tool_call",
        "data" => { "name" => "search_work_packages", "arguments" => {}, "error" => "KeyError" } },
      { "at" => Time.current.iso8601, "kind" => "answer", "data" => { "seconds" => 3.5, "tool_calls" => 4 } }
    ]
  end

  it "summarizes each tool call and the answer" do
    expect(rendered).to have_text("Called the tool search_work_packages: 0.2 s, 12 characters.")
    expect(rendered).to have_text("Called the tool search_work_packages again with the same arguments.")
    expect(rendered).to have_text("Refused the tool search_work_packages: the limit of tool calls is reached.")
    expect(rendered).to have_text("The tool search_work_packages failed (KeyError).")
    expect(rendered).to have_text("The model answered in 3.5 s, after 4 tool calls.")
  end

  it "shows the arguments and the result of a tool call, and the model's text between calls" do
    expect(rendered).to have_text(%("project_id": 1))
    expect(rendered).to have_text(%({"total":12}))
    expect(rendered).to have_text("The model explained its next tool calls.")
    expect(rendered).to have_text("Counting once more.")
  end
end
