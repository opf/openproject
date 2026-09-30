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
require_module_spec_helper

RSpec.describe Llm::Adapters::Openai, :llm_server_helpers, :webmock do
  subject(:adapter) { described_class.new(connection) }

  let(:base_url) { "https://example.com/v1" }
  let(:connection) { build(:llm_connection, base_url:, api_format: "openai", api_key: "sk-test") }

  describe "#models" do
    it "reads the cards of the catalogue" do
      mock_llm_models_response(base_url)

      expect(adapter.models.pluck(:id)).to contain_exactly("qwen3.6-27b", "bge-m3")
    end

    it "skips a bare array's entries that are not model cards" do
      mock_llm_models_response(base_url, body: [nil, 5, "grid", ["id"], { id: "bge-m3" }].to_json)

      expect(adapter.models.pluck(:id)).to eq(["bge-m3"])
      expect(adapter.server_flavour).to eq("unknown")
    end
  end
end
