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

RSpec.describe Llm::StructuredOutput do
  def message(content)
    instance_double(RubyLLM::Message, content:)
  end

  it "returns the structure with symbol keys" do
    expect(described_class.parse!(message({ "summary" => "hi", "tags" => %w[a b] })))
      .to eq(summary: "hi", tags: %w[a b])
  end

  it "symbolizes nested keys" do
    expect(described_class.parse!(message({ "a" => { "b" => 1 } }))).to eq(a: { b: 1 })
  end

  # RubyLLM rescues a JSON parse failure and leaves the content a String, so
  # without this the caller gets a String where it expected a Hash and only
  # notices much further downstream.
  it "raises when the model answered in prose instead" do
    expect { described_class.parse!(message("Sure! Here is the summary you asked for.")) }
      .to raise_error(Llm::Errors::ParseError)
  end

  it "accepts a bare structure as well as a message" do
    expect(described_class.parse!({ "a" => 1 })).to eq(a: 1)
  end
end
