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

RSpec.describe LlmConnection do
  describe "#api_key", with_config: { "database_cipher_key" => "secret" } do
    it "is stored as it was given, even with a cipher key configured" do
      connection = create(:llm_connection, api_key: "sk-plain-key")

      expect(connection.reload.api_key).to eq("sk-plain-key")
      expect(described_class.where(id: connection.id).pick(:api_key)).to eq("sk-plain-key")
    end
  end

  describe "#api_key_stored?" do
    it "is false for a connection that was never saved" do
      expect(build(:llm_connection, api_key: "sk-test-key")).not_to be_api_key_stored
    end

    it "is false for a saved connection without a key" do
      expect(create(:llm_connection, api_key: nil)).not_to be_api_key_stored
    end

    it "is true for a saved connection with a key" do
      expect(create(:llm_connection, api_key: "sk-test-key")).to be_api_key_stored
    end

    it "is false when a key was assigned but the save failed" do
      connection = create(:llm_connection, api_key: nil)
      connection.assign_attributes(api_key: "sk-test-key", base_url: "")

      expect(connection.save).to be(false)
      expect(connection).not_to be_api_key_stored
    end
  end

  describe "the single active connection" do
    it "allows only one connection to be active" do
      create(:llm_connection)
      second = build(:llm_connection, active: true)

      expect(second).not_to be_valid
      expect(second.errors).to be_of_kind(:base, :singleton)
    end

    it "allows any number of inactive connections beside it" do
      create(:llm_connection)

      expect(build(:llm_connection, active: false)).to be_valid
    end

    it "is capped by the database as well as the validation" do
      create(:llm_connection)
      second = build(:llm_connection, active: true)

      expect { second.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "hands out the active connection, unsaved when there is none" do
      expect(described_class.active_connection).to be_new_record
      expect(described_class.active_connection).to be_active

      connection = create(:llm_connection)

      expect(described_class.active_connection).to eq(connection)
    end
  end

  describe "#settings_fingerprint" do
    subject(:connection) { build(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-test") }

    it "changes with the API format" do
      expect { connection.api_format = "anthropic" }.to change(connection, :settings_fingerprint)
    end

    it "changes with the host URL" do
      expect { connection.base_url = "https://elsewhere.example/v1" }.to change(connection, :settings_fingerprint)
    end

    it "changes with the API key" do
      expect { connection.api_key = "sk-rotated" }.to change(connection, :settings_fingerprint)
    end
  end

  describe "#models_stale?" do
    subject(:connection) { create(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-test") }

    it "is false while no model list has been fetched" do
      expect(connection).not_to be_models_stale
    end

    it "is false while the settings still match the fetched list" do
      connection.update!(connection_fingerprint: connection.settings_fingerprint)

      expect(connection).not_to be_models_stale
    end

    it "is true once a connection setting changed" do
      connection.update!(connection_fingerprint: connection.settings_fingerprint)
      connection.update!(api_key: "sk-rotated")

      expect(connection).to be_models_stale
    end
  end
end
