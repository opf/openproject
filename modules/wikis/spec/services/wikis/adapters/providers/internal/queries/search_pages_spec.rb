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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::SearchPages do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:input_data) { Wikis::Adapters::Input::SearchPages.build(query:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }
  let(:query) { wiki_page.title }

  let(:wiki) { create(:wiki) }
  let(:wiki_project) { wiki.project }
  let(:wiki_page) { create(:wiki_page, wiki:, parent: wiki_page_parent, title: "Wiki Page with a Title you will love") }
  let(:wiki_page_parent) { create(:wiki_page, wiki:, title: "Nothing to see here") }
  let(:wiki_project_permissions) { %i[view_wiki_pages] }

  let(:user) { create(:user, member_with_permissions: { wiki_project => wiki_project_permissions }) }

  before do
    wiki_page
  end

  it { is_expected.to be_success }

  it "returns pages matching the search term exactly" do
    expect(subject.value!).not_to be_empty
    expect(subject.value!.first.page.title).to eq(wiki_page.title)
  end

  it "returns the page's ancestors" do
    expect(subject.value!).not_to be_empty
    expect(subject.value!.first.ancestors.first.identifier).to eq(wiki_page_parent.id.to_s)
  end

  it "returns the page's wiki" do
    expect(subject.value!).not_to be_empty
    expect(subject.value!.first.wiki.identifier).to eq(wiki.id.to_s)
  end

  context "when the search term only matches partially" do
    let(:query) { "a Title" }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.page.title).to eq(wiki_page.title)
    end
  end

  context "when the search term matches a parent page" do
    let(:query) { wiki_page_parent.title }
    let!(:wiki_page_child) { create(:wiki_page, wiki:, parent: wiki_page, title: "Deeply nested page") }

    it { is_expected.to be_success }

    it "returns the matching page only, not the pages nested below it" do
      expect(subject.value!.map { it.page.title }).to contain_exactly(wiki_page_parent.title)
    end
  end

  context "when the search term has wrong casing" do
    let(:query) { wiki_page.title.downcase }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.page.title).to eq(wiki_page.title)
    end
  end

  context "when the search term only matches the name of the page's wiki" do
    let(:query) { wiki_project.name }

    it { is_expected.to be_success }

    it "returns an empty result, as wikis are searched separately" do
      expect(subject.value!).to eq([])
    end
  end

  context "when there are no matching pages" do
    let(:query) { "the title" }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end

  context "when user can't see a matching wiki page" do
    let(:wiki_project_permissions) { %i[] }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end
end
