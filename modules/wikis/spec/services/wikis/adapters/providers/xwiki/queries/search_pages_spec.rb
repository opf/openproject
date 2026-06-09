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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::SearchPages, :disable_ssrf_filter, :webmock do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
  let(:input_data) { Wikis::Adapters::Input::SearchPages.build(query:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }

  let(:user) { create(:user) }

  # Before recording VCR cassettes of this, ensure pages with the following titles exist in XWiki:
  # * Test Page for RSpec
  # * "Quoted" pages can be tricky

  context "when there are exactly matching pages", vcr: "xwiki/query_exact_match" do
    let(:query) { "Test Page for RSpec" }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.title).to eq("Test Page for RSpec")
    end

    it "returns a complete PageInfo result" do
      page_info = subject.value!.first
      page_info.to_h.each do |attribute, value|
        expect(value).not_to be_nil, "#{attribute} was expected to be non-nil, but was nil"
      end
    end

    it "returns no other random results" do
      expect(subject.value!.count).to eq(1)
    end
  end

  context "when there are partially matching pages", vcr: "xwiki/query_partial_match" do
    let(:query) { "for RSpec" }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.title).to eq("Test Page for RSpec")
    end

    it "returns no other random results" do
      expect(subject.value!.count).to eq(1)
    end
  end

  context "when the searched page contains quotes", vcr: "xwiki/query_quoted_match" do
    let(:query) { '"Quoted" pages can be tricky' }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.title).to eq('"Quoted" pages can be tricky')
    end

    it "returns no other random results" do
      expect(subject.value!.count).to eq(1)
    end

    context "and the query omits the quotes", vcr: "xwiki/query_unquoted_match" do
      let(:query) { "Quoted pages can be tricky" }

      it { is_expected.to be_success }

      it "returns matching pages" do
        expect(subject.value!).not_to be_empty
        expect(subject.value!.first.title).to eq('"Quoted" pages can be tricky')
      end
    end
  end

  context "when there are no matching pages", vcr: "xwiki/query_no_match" do
    let(:query) { "A page that does not exist" }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end
end
