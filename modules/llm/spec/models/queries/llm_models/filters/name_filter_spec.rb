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

RSpec.describe Queries::LlmModels::Filters::NameFilter do
  let(:connection) { create(:llm_connection, base_url: "https://example.com/v1") }
  let!(:qwen) { create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b") }
  let!(:named) { create(:llm_model, llm_connection: connection, external_id: "bge-m3", display_name: "Embedder") }
  let!(:reported) do
    create(:llm_model, llm_connection: connection, external_id: "google/gemma-4", raw_metadata: { "name" => "Gemma Four" })
  end

  def matches(operator, value)
    filter = described_class.create!(operator:, values: Array(value))
    LlmModel.where(filter.where).pluck(:external_id)
  end

  it "resolves every operator it accepts" do
    operators = described_class.create!(operator: "~", values: ["x"]).available_operators.map(&:symbol)
    expect(operators).to include("=", "!", "~", "!~")

    operators.each do |operator|
      filter = described_class.create!(operator:, values: ["qwen3.6-27b"])

      expect(filter.where).to be_present, "operator #{operator} has no condition"
      expect { matches(operator, "qwen3.6-27b") }.not_to raise_error
    end
  end

  it "matches a substring of the identifier or the display name" do
    expect(matches("~", "qwen")).to contain_exactly("qwen3.6-27b")
    expect(matches("~", "embed")).to contain_exactly("bge-m3")
  end

  it "matches a substring of the name the server or a registry reports" do
    expect(matches("~", "four")).to contain_exactly("google/gemma-4")
  end

  it "excludes a substring, keeping rows that have no display name or reported name" do
    expect(matches("!~", "qwen")).to contain_exactly("bge-m3", "google/gemma-4")
  end

  it "excludes a substring of the reported name" do
    expect(matches("!~", "four")).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  it "matches an exact identifier or display name" do
    expect(matches("=", "qwen3.6-27b")).to contain_exactly("qwen3.6-27b")
    expect(matches("=", "Embedder")).to contain_exactly("bge-m3")
    expect(matches("=", "Gemma Four")).to contain_exactly("google/gemma-4")
    expect(matches("=", "qwen")).to be_empty
  end

  it "excludes an exact identifier, keeping rows that have no display name or reported name" do
    expect(matches("!", "qwen3.6-27b")).to contain_exactly("bge-m3", "google/gemma-4")
  end

  it "excludes an exact reported name" do
    expect(matches("!", "Gemma Four")).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  it "matches nothing rather than raising on an empty term" do
    expect(matches("~", nil)).to be_empty
  end
end
