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

RSpec.shared_examples_for "MCP result response" do
  let(:json_rpc_response_schema) do
    {
      required: %w[jsonrpc id result],
      properties: {
        id: { type: "string" },
        jsonrpc: { type: "string", enum: ["2.0"] },
        result: { type: "object" }
      }
    }
  end

  it "returns a success" do
    subject
    expect(last_response).to have_http_status(200)
  end

  it "has no WWW-Authenticate header" do
    subject
    expect(last_response.headers["WWW-Authenticate"]).to be_nil
  end

  it "fulfills the schema of a JSON RPC response" do
    subject
    expect(last_response.body).to match_json_schema(json_rpc_response_schema)
  end
end

RSpec.shared_examples_for "MCP tool execution error response" do
  let(:result_schema) do
    {
      required: %w[result],
      properties: {
        result: {
          required: %w[isError content],
          properties: {
            isError: { type: "boolean" },
            content: { type: "array" },
            structuredContent: { type: ["object"] }
          }
        }
      }
    }
  end

  include_context "MCP result response"

  it "fulfills the schema of an MCP response" do
    subject
    expect(last_response.body).to match_json_schema(result_schema)
  end

  it "is an error" do
    subject
    expect(JSON(last_response.body).dig("result", "isError")).to be true
  end
end

RSpec.shared_examples_for "MCP response with structured content" do
  let(:result_schema) do
    {
      required: %w[result],
      properties: {
        result: {
          required: %w[isError content structuredContent],
          properties: {
            isError: { type: "boolean" },
            content: { type: "array" },
            structuredContent: { type: ["object"] }
          }
        }
      }
    }
  end

  include_context "MCP result response"

  it "fulfills the schema of a structured MCP response" do
    subject
    expect(last_response.body).to match_json_schema(result_schema)
  end
end

RSpec.shared_examples_for "MCP text resource response" do
  let(:result_schema) do
    {
      required: %w[result],
      properties: {
        result: {
          type: "object",
          required: %w[contents],
          properties: {
            contents: {
              type: "array",
              items: {
                type: "object",
                required: %w[uri text],
                properties: {
                  uri: { type: "string" },
                  mimeType: { type: "string" },
                  text: { type: "string" }
                }
              }
            }
          }
        }
      }
    }
  end

  include_context "MCP result response"

  it "fulfills the schema of a text resource" do
    subject
    expect(last_response.body).to match_json_schema(result_schema)
  end
end

RSpec.shared_examples_for "MCP empty resource response" do
  include_context "MCP text resource response"

  it "has no contents" do
    subject
    parsed = JSON.parse(last_response.body)
    expect(parsed.dig("result", "contents")).to be_empty
  end
end

RSpec.shared_examples_for "MCP error response" do
  let(:json_rpc_response_schema) do
    {
      required: %w[jsonrpc id error],
      properties: {
        id: { type: "string" },
        jsonrpc: { type: "string", enum: ["2.0"] },
        error: {
          type: "object",
          required: %w[code message data],
          properties: {
            code: { type: "number" },
            message: { type: "string" },
            data: { type: "string" }
          }
        }
      }
    }
  end

  it "returns a success" do
    subject
    expect(last_response).to have_http_status(200)
  end

  it "has no WWW-Authenticate header" do
    subject
    expect(last_response.headers["WWW-Authenticate"]).to be_nil
  end

  it "fulfills the schema of a JSON RPC error response" do
    subject
    expect(last_response.body).to match_json_schema(json_rpc_response_schema)
  end
end

RSpec.shared_examples_for "MCP unauthenticated response" do
  it "returns a 401 Unauthenticated" do
    subject
    expect(last_response).to have_http_status(401)
  end

  it "has a WWW-Authenticate header" do
    subject
    expect(last_response.headers["WWW-Authenticate"]).to be_present
  end

  it "indicates resource_metadata in the WWW-Authenticate header" do
    subject
    keys = last_response.headers["WWW-Authenticate"].split.select { |s| s.include?("=") }.map { |s| s.split("=").first }
    expect(keys).to include("resource_metadata")
  end
end

RSpec.shared_examples_for "MCP text tool" do
  it_behaves_like "MCP response with structured content"

  it "also includes text content" do
    subject
    content = parsed_results.fetch("content").first
    expect(content).not_to be_nil
    expect(content.fetch("type")).to eq("text")
  end

  context "when setting tool response format to structured_only", with_config: { mcp_tool_response_format: :structured_only } do
    it_behaves_like "MCP response with structured content"

    it "includes no content" do
      subject
      content = parsed_results.fetch("content").first
      expect(content).to be_nil
    end
  end

  context "when setting tool response format to content_only", with_config: { mcp_tool_response_format: :content_only } do
    it_behaves_like "MCP result response"

    it "includes text content" do
      subject
      content = parsed_results.fetch("content").first
      expect(content).not_to be_nil
      expect(content.fetch("type")).to eq("text")
    end

    it "includes no structured content" do
      subject
      expect(parsed_results.key?("structuredContent")).to be_falsey # rubocop:disable RSpec/PredicateMatcher
    end
  end

  context "when the tool is disabled via configuration" do
    let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name, enabled: false) }

    it_behaves_like "MCP error response"
  end
end

RSpec.shared_examples_for "MCP embedded resource tool" do
  it_behaves_like "MCP response with structured content"

  it "also includes resource content" do
    subject
    content = parsed_results.fetch("content").first
    expect(content).not_to be_nil
    expect(content.fetch("type")).to eq("resource")
  end

  context "when setting tool response format to structured_only", with_config: { mcp_tool_response_format: :structured_only } do
    it_behaves_like "MCP response with structured content"

    it "includes no content" do
      subject
      content = parsed_results.fetch("content").first
      expect(content).to be_nil
    end
  end

  context "when setting tool response format to content_only", with_config: { mcp_tool_response_format: :content_only } do
    it_behaves_like "MCP result response"

    it "includes resource content" do
      subject
      content = parsed_results.fetch("content").first
      expect(content).not_to be_nil
      expect(content.fetch("type")).to eq("resource")
    end

    it "includes no structured content" do
      subject
      expect(parsed_results.key?("structuredContent")).to be_falsey # rubocop:disable RSpec/PredicateMatcher
    end
  end

  context "when the tool is disabled via configuration" do
    let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name, enabled: false) }

    it_behaves_like "MCP error response"
  end
end
