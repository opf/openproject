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

RSpec.describe Llm::Adapters do
  def adapter_for(api_format)
    described_class.for(build(:llm_connection, api_format:))
  end

  describe ".for" do
    it "queries the server of a format that lists models in the OpenAI shape" do
      expect(adapter_for("openai")).to be_a(Llm::Adapters::Openai)
      expect(adapter_for("openrouter")).to be_a(Llm::Adapters::Openai)
    end

    it "reads the registry for a format that lists models its own way" do
      expect(adapter_for("anthropic")).to be_a(Llm::Adapters::RegistryBacked)
      expect(adapter_for("perplexity")).to be_a(Llm::Adapters::RegistryBacked)
    end

    it "rejects a format that is not offered" do
      expect { adapter_for("nonsense") }.to raise_error(Llm::Adapters::UnsupportedFormat, "nonsense")
    end
  end

  describe ".live_discovery?" do
    it "answers for a symbol as well as a string" do
      expect(described_class).to be_live_discovery(:ollama)
      expect(described_class).not_to be_live_discovery(:gemini)
    end
  end
end
