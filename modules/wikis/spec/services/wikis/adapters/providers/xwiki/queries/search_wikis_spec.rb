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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::SearchWikis, :disable_ssrf_filter, :webmock do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
  let(:input_data) { Wikis::Adapters::Input::SearchPages.build(query:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }

  let(:user) { create(:user) }

  # The recorded instance is no farm, so it hosts the main wiki named "xwiki" only.
  context "when the search term matches the name of a wiki", vcr: "xwiki/wikis" do
    let(:query) { "xwiki" }

    it { is_expected.to be_success }

    it "returns that wiki" do
      expect(subject.value!.map(&:identifier)).to contain_exactly("xwiki")
    end

    it "returns a complete Wiki result" do
      wiki = subject.value!.first

      expect(wiki).to be_a(Wikis::Adapters::Results::Wiki)
      wiki.to_h.each do |attribute, value|
        expect(value).not_to be_nil, "#{attribute} was expected to be non-nil, but was nil"
      end
    end

    it "returns the wiki's home as its URL" do
      expect(subject.value!.first.href).to eq("#{provider.url.chomp('/')}/bin/view/Main/")
    end
  end

  context "when the search term only matches partially", vcr: "xwiki/wikis" do
    let(:query) { "wik" }

    it { is_expected.to be_success }

    it "returns matching wikis" do
      expect(subject.value!.map(&:identifier)).to contain_exactly("xwiki")
    end
  end

  context "when the search term has wrong casing", vcr: "xwiki/wikis" do
    let(:query) { "XWiki" }

    it { is_expected.to be_success }

    it "returns matching wikis" do
      expect(subject.value!.map(&:identifier)).to contain_exactly("xwiki")
    end
  end

  context "when there are no matching wikis", vcr: "xwiki/wikis" do
    let(:query) { "A wiki that does not exist" }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end
end
