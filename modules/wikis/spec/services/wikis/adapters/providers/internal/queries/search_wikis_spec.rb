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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::SearchWikis do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:input_data) { Wikis::Adapters::Input::SearchPages.build(query:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }
  let(:query) { "Demo project" }

  let(:wiki) { create(:wiki, project: create(:project, name: "Demo project")) }
  let(:wiki_project_permissions) { %i[view_wiki_pages] }

  let(:user) { create(:user, member_with_permissions: { wiki.project => wiki_project_permissions }) }

  it { is_expected.to be_success }

  it "returns wikis whose project name matches the search term exactly" do
    expect(subject.value!.map(&:identifier)).to contain_exactly(wiki.id.to_s)
  end

  it "returns the wiki named after its project" do
    expect(subject.value!.first.name).to eq("Demo project")
  end

  context "when the search term only matches partially" do
    let(:query) { "emo pro" }

    it { is_expected.to be_success }

    it "returns matching wikis" do
      expect(subject.value!.map(&:identifier)).to contain_exactly(wiki.id.to_s)
    end
  end

  context "when the search term has wrong casing" do
    let(:query) { "demo PROJECT" }

    it { is_expected.to be_success }

    it "returns matching wikis" do
      expect(subject.value!.map(&:identifier)).to contain_exactly(wiki.id.to_s)
    end
  end

  context "when the search term only matches a page of the wiki" do
    let!(:wiki_page) { create(:wiki_page, wiki:, title: "Nothing to see here") }
    let(:query) { wiki_page.title }

    it { is_expected.to be_success }

    it "returns an empty result, as pages are searched separately" do
      expect(subject.value!).to eq([])
    end
  end

  context "when there are no matching wikis" do
    let(:query) { "Rebel Alliance" }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end

  context "when the user can't see the matching wiki" do
    let(:wiki_project_permissions) { %i[] }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end

  context "when the matching wiki is disabled" do
    let(:wiki) { create(:wiki, enabled: false, project: create(:project, name: "Demo project")) }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end
end
