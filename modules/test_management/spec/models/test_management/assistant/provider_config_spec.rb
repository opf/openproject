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

RSpec.describe TestManagement::Assistant::ProviderConfig do
  let(:valid) do
    { "assistant_base_url" => "https://api.example.test/v1", "assistant_model" => "gpt-test",
      "assistant_api_key" => "sk-secret-123" }
  end

  describe ".apply" do
    it "stores the key encrypted and keeps other module settings" do
      merged, errors = described_class.apply({ "default_display_prefix" => "QA" }, valid)

      expect(errors).to be_empty
      expect(merged["default_display_prefix"]).to eq("QA")
      expect(merged["assistant_api_key_ciphertext"]).to be_present
      expect(merged.values.join).not_to include("sk-secret-123")
      expect(described_class.new(merged).api_key).to eq("sk-secret-123")
    end

    it "keeps the stored key when the field is blank and removes it on request" do
      stored, = described_class.apply({}, valid)

      kept, = described_class.apply(stored, valid.merge("assistant_api_key" => ""))
      expect(described_class.new(kept).api_key).to eq("sk-secret-123")

      removed, = described_class.apply(stored, valid.merge("remove_api_key" => "1"))
      expect(described_class.new(removed).api_key_set?).to be(false)
    end

    describe "the stored key after a provider or host change" do
      let(:stored) do
        described_class.apply({}, "assistant_provider" => "openai", "assistant_model" => "gpt-4o-mini",
                                  "assistant_api_key" => "sk-openai").first
      end

      it "is kept while provider and host stay the same" do
        kept, errors = described_class.apply(stored, "assistant_provider" => "openai", "assistant_model" => "gpt-4.1",
                                                     "assistant_api_key" => "")
        expect(errors).to be_empty
        expect(described_class.new(kept).api_key).to eq("sk-openai")
      end

      it "is not reused for another provider that needs a key: a new key is required" do
        result, errors = described_class.apply(stored, "assistant_provider" => "anthropic",
                                                       "assistant_model" => "claude-sonnet-4-5",
                                                       "assistant_api_key" => "")
        expect(errors.size).to eq(1)
        expect(result).to eq(stored)

        switched, errors = described_class.apply(stored, "assistant_provider" => "anthropic",
                                                         "assistant_model" => "claude-sonnet-4-5",
                                                         "assistant_api_key" => "sk-a")
        expect(errors).to be_empty
        expect(described_class.new(switched).api_key).to eq("sk-a")
      end

      it "is cleared when the new provider needs none (custom auth none)" do
        switched, errors = described_class.apply(stored, "assistant_provider" => "custom",
                                                         "assistant_base_url" => "http://local.test:11434/v1",
                                                         "assistant_model" => "llama3.1:8b",
                                                         "assistant_auth_style" => "none",
                                                         "assistant_api_key" => "")
        expect(errors).to be_empty
        expect(described_class.new(switched).api_key_set?).to be(false)
        expect(described_class.new(switched).headers).not_to have_key("Authorization")
      end

      it "is not sent to another host of a custom provider" do
        valid = self.valid.merge("assistant_provider" => "custom", "assistant_auth_style" => "bearer")
        custom = described_class.apply({}, valid).first
        _, errors = described_class.apply(custom,
                                          valid.merge("assistant_base_url" => "https://other.example.net/v1",
                                                      "assistant_api_key" => ""))
        expect(errors.size).to eq(1)

        same_host, errors = described_class.apply(custom,
                                                  valid.merge("assistant_base_url" => "https://API.example.test/gw/v1",
                                                              "assistant_api_key" => ""))
        expect(errors).to be_empty
        expect(described_class.new(same_host).api_key).to eq("sk-secret-123")

        keyless, errors = described_class.apply(custom, valid.merge("assistant_base_url" => "https://other.example.net/v1",
                                                                    "assistant_auth_style" => "none", "assistant_api_key" => ""))
        expect(errors).to be_empty
        expect(described_class.new(keyless).api_key_set?).to be(false)
      end

      it "can be removed explicitly while switching" do
        result, errors = described_class.apply(stored, "assistant_provider" => "anthropic",
                                                       "assistant_model" => "claude-sonnet-4-5",
                                                       "remove_api_key" => "1")
        expect(errors).to be_empty
        expect(described_class.new(result).api_key_set?).to be(false)
      end
    end

    it "rejects invalid URLs, auth styles and ranges without changing anything" do
      stored = { "x" => 1 }
      [
        { "assistant_base_url" => "ftp://host" },
        { "assistant_base_url" => "https://user:pw@host" },
        { "assistant_auth_style" => "basic" },
        { "assistant_timeout" => "5" },
        { "assistant_max_tokens" => "999999" }
      ].each do |override|
        merged, errors = described_class.apply(stored, valid.merge(override))
        expect(errors).to be_present, override.inspect
        expect(merged).to eq(stored)
      end
    end
  end

  describe "instance" do
    it "builds the completions URL (also with a query string) and headers" do
      config = described_class.new(described_class.apply({}, valid).first)
      expect(config).to be_configured
      expect(config.label).to eq("api.example.test / gpt-test")
      expect(config.completions_url).to eq("https://api.example.test/v1/chat/completions")
      expect(config.headers).to include("Authorization" => "Bearer sk-secret-123")

      azure = described_class.new(described_class.apply({}, valid.merge(
                                                              "assistant_base_url" => "https://r.openai.azure.com/openai/deployments/d?api-version=2024-10-21",
                                                              "assistant_auth_style" => "api_key"
                                                            )).first)
      expect(azure.completions_url).to eq("https://r.openai.azure.com/openai/deployments/d/chat/completions?api-version=2024-10-21")
      expect(azure.headers).to include("api-key" => "sk-secret-123")
      expect(azure.headers).not_to include("Authorization")
    end

    it "needs a key unless the auth style is none" do
      local = { "assistant_provider" => "custom", "assistant_base_url" => "http://local.test:11434/v1",
                "assistant_model" => "llama3.1:8b" }
      expect(described_class.new(described_class.apply({}, local).first)).not_to be_configured
      expect(described_class.new(described_class.apply({},
                                                       local.merge("assistant_auth_style" => "none")).first)).to be_configured
    end

    it "is not configured without settings" do
      expect(described_class.new({})).not_to be_configured
    end
  end
end
