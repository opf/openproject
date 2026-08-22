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

RSpec.describe EnvData::LlmConnectionSeeder do
  subject(:seed) { described_class.new(seed_data).seed! }

  let(:seed_data) { Source::SeedData.new({}) }

  it "does not seed a connection without configuration" do
    expect { seed }.not_to change(LlmConnection, :count)
  end

  # On a fresh installation the seed runs before any model synchronisation, so
  # a configured default model cannot be validated against a catalogue yet.
  # Provisioning must still complete; a wrong id surfaces later as dangling.
  context "with a default model configured on a fresh installation", with_settings: {
    llm_connection: {
      "base_url" => "https://example.com/v1",
      "api_key" => "sk-from-env",
      "default_chat_model" => "qwen3.6-35b-a3b"
    }
  } do
    it "seeds the connection without contacting the server" do
      expect { seed }.to change(LlmConnection, :count).from(0).to(1)

      connection = LlmConnection.first
      expect(connection.default_chat_model_id).to eq("qwen3.6-35b-a3b")
      expect(connection.api_key).to eq("sk-from-env")
    end
  end

  # The environment is the source of truth while the form is read-only under it,
  # so a value removed from the environment must not linger in the database.
  context "when a previously set key is removed from the environment", with_settings: {
    llm_connection: { "base_url" => "https://example.com/v1" }
  } do
    before do
      create(:llm_connection, base_url: "https://example.com/v1",
                              api_key: "sk-stale",
                              default_chat_model_id: "old-default")
    end

    it "clears the values the environment no longer provides" do
      expect { seed }.not_to change(LlmConnection, :count)

      connection = LlmConnection.first
      expect(connection.api_key).to be_nil
      expect(connection.default_chat_model_id).to be_nil
      expect(connection.base_url).to eq("https://example.com/v1")
    end
  end
end
