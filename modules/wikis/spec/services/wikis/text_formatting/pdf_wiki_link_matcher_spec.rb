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
require_module_spec_helper

RSpec.describe Wikis::TextFormatting::PdfWikiLinkMatcher do
  shared_let(:user) { create(:user) }
  shared_let(:provider) { create(:internal_wiki_provider) }

  let(:formatter) { Class.new { extend Exports::PDF::Common::Macro } }
  let(:page_info_query) { instance_double(Wikis::Adapters::Providers::Internal::Queries::PageInfo) }
  let(:page_info_result) do
    Success(
      Wikis::Adapters::Results::PageInfo.new(
        identifier: "123abc",
        title: "Stormtrooper training",
        provider:,
        href: "https://wiki.example.com/Main/WebHome"
      )
    )
  end
  let(:markdown) { "Read \\[\\[\\[#{provider.id}:123abc\\]\\]\\] first" }

  subject(:result) { formatter.apply_markdown_field_macros(markdown, {}).strip }

  current_user { user }

  before do
    allow(Wikis::Provider).to receive(:find_by).and_call_original
    allow(Wikis::Provider).to receive(:find_by).with(id: provider.id.to_s).and_return(provider)
    allow(provider).to receive(:resolve).and_call_original
    allow(provider).to receive(:resolve).with("queries.page_info").and_return(page_info_query)
    allow(page_info_query).to receive(:call).and_return(page_info_result)
  end

  it "is registered as a PDF macro" do
    expect(Exports::PDF::Common::Macro.macros).to include(described_class)
  end

  context "when the page can be resolved" do
    it "replaces the wiki link with a link to the page", :aggregate_failures do
      expect(result).to eq('Read <a href="https://wiki.example.com/Main/WebHome">Stormtrooper training</a> first')
      expect(page_info_query).to have_received(:call) do |input_data:, auth_strategy:|
        expect(input_data.identifier).to eq("123abc")
        expect(auth_strategy.user).to eq(user)
      end
    end

    context "when the link is not escaped" do
      let(:markdown) { "Read [[[#{provider.id}:123abc]]] first" }

      it "replaces the wiki link with a link to the page" do
        expect(result).to eq('Read <a href="https://wiki.example.com/Main/WebHome">Stormtrooper training</a> first')
      end
    end
  end

  context "when resolving the page fails" do
    let(:page_info_result) do
      Failure(SimpleError.new(source: Wikis::Adapters::Providers::Internal::Queries::PageInfo, code: error_code))
    end

    context "when the page was not found" do
      let(:error_code) { :not_found }

      it { is_expected.to eq("Read Linked wiki page no longer available first") }
    end

    context "when access to the page is forbidden" do
      let(:error_code) { :unauthorized }

      it { is_expected.to eq("Read You do not have permission to access this wiki page first") }
    end

    context "when an unexpected error occurs" do
      let(:error_code) { :timeout }

      it { is_expected.to eq("Read An unexpected error occurred first") }
    end
  end

  context "when the provider does not exist" do
    let(:markdown) { '\[\[\[0:123abc\]\]\]' }

    it { is_expected.to eq("An unexpected error occurred") }
  end

  context "without a wiki link" do
    let(:markdown) { "Nothing to see here" }

    it "leaves the text unchanged" do
      expect(result).to eq(markdown)
    end
  end
end
