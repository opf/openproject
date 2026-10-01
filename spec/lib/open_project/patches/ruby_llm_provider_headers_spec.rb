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

RSpec.describe OpenProject::Patches::RubyLLMProviderHeaders do
  def provider_for(slug, custom_headers)
    context = RubyLLM.context do |config|
      config.public_send(:"#{slug}_api_key=", "test-key")
      config.openproject_custom_headers = custom_headers
      config.logger = Rails.logger
    end

    RubyLLM::Provider.resolve(slug).new(context.config)
  end

  it "adds the connection's custom headers to a provider's own" do
    headers = provider_for(:openai, { "apikey" => "gateway-secret" }).headers

    expect(headers).to include("apikey" => "gateway-secret")
    expect(headers).to include("Authorization" => "Bearer test-key")
  end

  # The point of the patch: a gateway may authenticate on its own terms, so an
  # administrator has to be able to replace what the provider would send.
  # RubyLLM's own Chat#with_headers merges the other way round and cannot.
  it "lets a custom header override the provider's" do
    headers = provider_for(:openai, { "Authorization" => "Bearer override" }).headers

    expect(headers).to include("Authorization" => "Bearer override")
  end

  it "accepts symbol keys" do
    headers = provider_for(:openai, { apikey: "gateway-secret" }).headers

    expect(headers).to include("apikey" => "gateway-secret")
  end

  it "leaves the provider's headers untouched when none are configured" do
    expect(provider_for(:openai, {}).headers).to eq(provider_for(:openai, nil).headers)
    expect(provider_for(:openai, nil).headers).to include("Authorization" => "Bearer test-key")
  end

  # All thirteen providers define #headers without calling super, so the patch
  # has to be prepended onto each one rather than onto the base class.
  it "applies to every registered provider" do
    RubyLLM::Provider.providers.each_value do |provider_class|
      expect(provider_class.ancestors).to include(described_class)
    end
  end

  it "reaches a provider that is not openai" do
    headers = provider_for(:anthropic, { "apikey" => "gateway-secret" }).headers

    expect(headers).to include("apikey" => "gateway-secret")
  end
end
