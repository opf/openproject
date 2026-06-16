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

RSpec.describe McpTools::SearchPrograms do
  subject do
    header "Authorization", "Bearer #{access_token.plaintext_token}"
    header "X-Authentication-Scheme", "Bearer"
    header "Content-Type", "application/json"
    post "/mcp", request_body.to_json
  end

  let(:access_token) { create(:oauth_access_token, scopes: "mcp", resource_owner: user) }
  let(:user) { create(:admin) } # using an admin, so that programs are visible
  let(:request_body) do
    {
      jsonrpc: "2.0",
      id: "Test-Request",
      method: "tools/call",
      params: {
        name: "search_programs",
        arguments: call_args
      }
    }
  end
  let(:call_args) { {} }
  let(:parsed_results) { JSON.parse(last_response.body).fetch("result") }

  let!(:program_a) { create(:program, identifier: "abc", name: "The ABC Program", status_code: :on_track) }
  let!(:program_b) { create(:program, identifier: "def", name: "The DEF Program", status_code: :off_track) }
  let!(:project) { create(:project, identifier: "ghi", name: "The unrelated Project", status_code: :on_track) }

  let(:server_config) { create(:mcp_configuration, identifier: "mcp_server") }
  let(:tool_config) { create(:mcp_configuration, identifier: described_class.qualified_name) }

  before do
    server_config.save!
    tool_config.save!
  end

  context "when the mcp_server enterprise feature is enabled", with_ee: %i[mcp_server] do
    it_behaves_like "MCP text tool"

    it "finds all programs without filters" do
      subject
      expect(parsed_results.dig("structuredContent", "items").size).to eq(2)
    end

    it "responds with properly formatted programs" do
      subject
      parsed_results.dig("structuredContent", "items").each do |program|
        expect(program.to_json).to match_json_schema.from_docs("program_model")
      end
    end

    context "when passing an exact identifier" do
      let(:call_args) { { identifier: "abc" } }

      it "finds the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_present
      end
    end

    context "when passing a non-exact identifier" do
      let(:call_args) { { identifier: "Abc" } }

      it "does not find the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_empty
      end
    end

    context "when passing an exact name" do
      let(:call_args) { { name: "The ABC Program" } }

      it "finds the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_present
      end
    end

    describe "pagination" do
      let(:page_size) { 10 }
      let(:overspilling_programs) { 5 }
      let(:program_count) { page_size + overspilling_programs }
      let(:call_args) { { name: "Death Star" } }

      before do
        allow(described_class).to receive(:page_size).and_return(page_size)

        program_count.times do |idx|
          create(:program,
                 identifier: "p#{idx}",
                 name: "Death Star construction phase #{idx}",
                 status_code: :on_track)
        end
      end

      it "returns only results up to the page size" do
        subject
        expect(parsed_results.dig("structuredContent", "items").count).to eq(page_size)
      end

      context "if another page is requested" do
        let(:call_args) { { name: "Death Star", page: 2 } }

        it "returns the requested page" do
          subject
          expect(parsed_results.dig("structuredContent", "items").count).to eq(overspilling_programs)
        end
      end
    end

    context "when passing a non-exact name" do
      let(:call_args) { { name: "The abc" } }

      it "finds the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_present
      end
    end

    context "when passing a program status" do
      let(:call_args) { { status_code: "on_track" } }

      it "finds the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_present
      end

      context "and when passing a program identifier" do
        let(:call_args) { { status_code: "on_track", identifier: "abc" } }

        it "finds the program" do
          subject
          expect(parsed_results.dig("structuredContent", "items")).to be_present
        end
      end

      context "and when passing the program identifier of a program in a different status" do
        let(:call_args) { { status_code: "on_track", identifier: "def" } }

        it "does not find the program" do
          subject
          expect(parsed_results.dig("structuredContent", "items")).to be_empty
        end
      end
    end

    context "when passing an invalid program status" do
      let(:call_args) { { status_code: "blubb" } }

      it_behaves_like "MCP tool execution error response"
    end

    context "when user can't see programs" do
      let(:user) { create(:user) }

      it "does not find the program" do
        subject
        expect(parsed_results.dig("structuredContent", "items")).to be_empty
      end
    end
  end

  context "when the mcp_server enterprise feature is disabled" do
    it "responds in a 404" do
      subject
      expect(last_response).to have_http_status(404)
    end
  end
end
