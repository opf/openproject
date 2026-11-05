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

RSpec.describe TestManagement::Assistant::ProviderSaveService, :disable_ssrf_filter, :webmock do
  def save(provider = TestManagement::AssistantProvider.new, **form) = described_class.new(provider).call(form.stringify_keys)

  it "creates the first provider as the default with the key encrypted" do
    result = save(name: "OpenAI", assistant_provider: "openai", assistant_model: "gpt-4o-mini", assistant_api_key: "sk-new",
                  user_models: "gpt-4o")

    expect(result).to be_success
    expect(result.provider).to have_attributes(is_default: true, preset: "openai", user_models: %w[gpt-4o])
    expect(result.provider.config.api_key).to eq("sk-new")
  end

  it "makes a later provider default only when asked" do
    custom = { assistant_provider: "custom", assistant_base_url: "http://a.test/v1", assistant_model: "m",
               assistant_auth_style: "none" }
    first = save(name: "A", **custom).provider
    second = save(name: "B", **custom).provider
    expect([first.reload.is_default, second.is_default]).to eq([true, false])

    save(second, name: "B", **custom, make_default: "1")
    expect([first.reload.is_default, second.reload.is_default]).to eq([false, true])
  end

  it "applies the key rule per provider" do
    provider = save(name: "OpenAI", assistant_provider: "openai", assistant_model: "gpt-4o", assistant_api_key: "sk-old").provider
    other = save(name: "Second", assistant_provider: "openai", assistant_model: "gpt-4o", assistant_api_key: "sk-other").provider

    kept = save(provider, assistant_provider: "openai", assistant_model: "gpt-4o-mini", assistant_api_key: "")
    expect(kept).to be_success
    expect(provider.reload.config.api_key).to eq("sk-old")

    switched = save(provider, assistant_provider: "anthropic", assistant_model: "claude-sonnet-4-5", assistant_api_key: "")
    expect(switched).not_to be_success
    expect(switched.errors.size).to eq(1)
    expect(provider.reload.preset).to eq("openai")
    expect(other.reload.config.api_key).to eq("sk-other")
  end

  it "keeps the name when the form has none (API PATCH)" do
    provider = save(name: "Keep", assistant_provider: "custom", assistant_base_url: "http://a.test/v1",
                    assistant_model: "m", assistant_auth_style: "none").provider

    expect(save(provider, assistant_provider: "custom", assistant_base_url: "http://a.test/v1",
                          assistant_model: "m2", assistant_auth_style: "none")).to be_success
    expect(provider.reload).to have_attributes(name: "Keep", model: "m2")
  end

  it "reports validation errors without saving" do
    result = save(name: "", assistant_provider: "custom", assistant_base_url: "ftp://nope", assistant_model: "m")

    expect(result).not_to be_success
    expect(result.errors.size).to be >= 2
    expect(TestManagement::AssistantProvider.count).to eq(0)
  end

  describe "verify_model" do
    it "saves after the model answered" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: { choices: [{ message: { role: "assistant", content: "OK" } }] }.to_json)

      result = save(name: "OpenAI", assistant_provider: "openai", assistant_model: "gpt-4o-mini", assistant_api_key: "sk-v",
                    verify_model: "1")

      expect(result).to be_success
      expect(result.verification).to be_ok
    end

    it "saves nothing when the model does not answer" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 403, body: { error: { message: "no access to gpt-x for sk-v" } }.to_json)

      result = save(name: "OpenAI", assistant_provider: "openai", assistant_model: "gpt-x", assistant_api_key: "sk-v",
                    verify_model: "1")

      expect(result).not_to be_success
      expect(result.errors.join).not_to include("sk-v")
      expect(TestManagement::AssistantProvider.count).to eq(0)
    end
  end
end
