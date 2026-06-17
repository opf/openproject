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

RSpec.describe Wikis::Adapters::Providers::XWiki::Commands::CreatePage, :disable_ssrf_filter, :webmock do
  describe "#call" do
    subject(:result) { described_class.new(model: provider).call(input_data:, auth_strategy:) }

    let(:provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
    let(:auth_strategy) { Wikis::Adapters::Input::AuthStrategy.build(key: :bearer_token, user:, provider:).value! }
    let(:input_data) { Wikis::Adapters::Input::CreatePage.build(title:, parent_identifier:).value! }
    let(:user) { create(:user) }

    let(:title) { "A page automatically created during a create_page test" }
    # To record a VCR cassette, make sure to set parent_identifier to the stable ID of an existing wiki page
    # and parent_title to that wiki page's title.
    # Pages created in the run of these tests should be deleted again afterwards for repeatability
    let(:parent_identifier) { "d65fa" }
    let(:parent_title) { "Test Page for RSpec" }

    it "successfully creates a page", vcr: "xwiki/create_page_and_confirm" do
      expect(result).to be_success
      id = result.value!.identifier

      input = Wikis::Adapters::Input::PageInfo.build(identifier: id).value!
      confirmation = provider.resolve("queries.page_info").call(input_data: input, auth_strategy:)

      expect(confirmation).to be_success
      expect(confirmation.value!.title).to eq(title)

      aggregate_failures "making the page a child of the intended parent" do
        expected_prefix = Regexp.new("^#{Regexp.escape("xwiki:#{parent_title}.")}")
        expect(WebMock).to have_requested(:put, "https://xwiki.local/rest/openproject/documents")
          .with(query: hash_including(docRef: expected_prefix))
      end

      aggregate_failures "allowing the created page to have child pages" do
        expected_suffix = /\.WebHome$/
        expect(WebMock).to have_requested(:put, "https://xwiki.local/rest/openproject/documents")
          .with(query: hash_including(docRef: expected_suffix))
      end
    end

    context "when the parent does not exist", vcr: "xwiki/create_page_not_found" do
      let(:parent_identifier) { "abc123" }

      it "returns a :not_found error" do
        expect(result).to be_failure
        expect(result.failure.code).to eq(:not_found)
      end

      it "does not create a page" do
        result

        expect(WebMock).not_to have_requested(:put, %r{https://xwiki.local/rest/openproject/documents})
      end
    end
  end

  describe ".derive_page_id" do
    subject { described_class.derive_page_id(title) }

    let(:title) { "My simple title" }

    it "does not interfere with the title" do
      expect(subject).to eq(title)
    end

    context "when the title contains emoji and umlauts" do
      let(:title) { "Mein schöner Titel 🐈" }

      it "does not interfere with the title" do
        expect(subject).to eq(title)
      end
    end

    context "when the title contains colons or dots" do
      let(:title) { "Release notes: 1.0.0" }

      it "escapes colons and dots" do
        expect(subject).to eq("Release notes\\: 1\\.0\\.0")
      end
    end

    context "when the title contains backslashes" do
      let(:title) { "C:\\Windows\\System32 is a windows-style path" }

      it "removes backslashes" do
        expect(subject).to eq("C\\:WindowsSystem32 is a windows-style path")
      end
    end
  end
end
