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

  let(:wiki_page) { create(:wiki_page, title: "Wiki Page with a Title you will love") }
  let(:wiki_project) { wiki_page.project }
  let(:wiki_project_permissions) { %i[view_wiki_pages] }

  let(:user) { create(:user) }

  before do
    create(:member, project: wiki_project,
                    user:,
                    roles: [create(:project_role, permissions: wiki_project_permissions)])

    wiki_page
  end

  it { is_expected.to be_success }

  it "returns pages matching the search term exactly" do
    expect(subject.value!).not_to be_empty
    expect(subject.value!.first.title).to eq(wiki_page.title)
  end

  context "when the search term only matches partially" do
    let(:query) { "a Title" }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.title).to eq(wiki_page.title)
    end
  end

  context "when the search term has wrong casing" do
    let(:query) { wiki_page.title.downcase }

    it { is_expected.to be_success }

    it "returns matching pages" do
      expect(subject.value!).not_to be_empty
      expect(subject.value!.first.title).to eq(wiki_page.title)
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
