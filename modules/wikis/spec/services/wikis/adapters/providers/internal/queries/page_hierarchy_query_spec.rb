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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::PageHierarchy do
  it "is not registered" do
    expect { Wikis::Adapters::Registry.resolve("internal.queries.page_hierarchy") }
      .to raise_error Wikis::Adapters::Registry::OperationNotSupported
  end

  describe "#call" do
    subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

    let(:provider) { create(:internal_wiki_provider) }
    let(:input_data) { Wikis::Adapters::Input::PageHierarchy.build(identifier:).value! }
    let(:auth_strategy) { provider.auth_strategy_for(user).value! }
    let(:identifier) { wiki_page.id.to_s }

    let(:wiki) { create(:wiki) }
    let(:wiki_project) { wiki.project }
    let(:wiki_page) { create(:wiki_page, wiki:, parent: wiki_page_parent, title: "TIE Hangar 73c-s7x") }
    let(:wiki_page_parent) { create(:wiki_page, wiki:, parent: wiki_page_grandparent, title: "Small size star ships") }
    let(:wiki_page_grandparent) { create(:wiki_page, wiki:, title: "Hangar specifications") }
    let(:wiki_project_permissions) { %i[view_wiki_pages] }

    let(:user) { create(:user, member_with_permissions: { wiki_project => wiki_project_permissions }) }

    before do
      wiki_page
    end

    it { is_expected.to be_success }

    it "returns the page matching the requested identifier" do
      page = subject.value!.page
      expect(page.identifier).to eq(identifier)
      expect(page.provider).to eq(provider)
      expect(page.title).to eq(wiki_page.title)
      expect(page.href).to eq("/projects/#{wiki_project.identifier}/wiki/#{wiki_page.slug}")
    end

    it "returns the wiki the requested page belongs to" do
      wiki_data = subject.value!.wiki
      expect(wiki_data.identifier).to eq(wiki.id.to_s)
      expect(wiki_data.provider).to eq(provider)
      expect(wiki_data.name).to eq(wiki_project.name)
      expect(wiki_data.href).to eq("/projects/#{wiki_project.identifier}")
    end

    it "returns the ancestors of the requested page" do
      ancestors = subject.value!.ancestors
      expect(ancestors.size).to eq(2)
      expect(ancestors[0].identifier).to eq(wiki_page_parent.id.to_s)
      expect(ancestors[1].identifier).to eq(wiki_page_grandparent.id.to_s)
    end

    context "if the requested page is a main page" do
      let(:main_page) { create(:wiki_page, wiki:, title: "Death Star Home") }
      let(:identifier) { main_page.id.to_s }

      it "returns the page matching the requested identifier" do
        page = subject.value!.page
        expect(page.identifier).to eq(identifier)
        expect(page.provider).to eq(provider)
        expect(page.title).to eq(main_page.title)
        expect(page.href).to eq("/projects/#{wiki_project.identifier}/wiki/#{main_page.slug}")
      end

      it "returns the wiki the requested page belongs to" do
        wiki_data = subject.value!.wiki
        expect(wiki_data.identifier).to eq(wiki.id.to_s)
        expect(wiki_data.provider).to eq(provider)
        expect(wiki_data.name).to eq(wiki_project.name)
        expect(wiki_data.href).to eq("/projects/#{wiki_project.identifier}")
      end

      it "returns an empty list of ancestors" do
        ancestors = subject.value!.ancestors
        expect(ancestors).to be_empty
      end
    end

    context "when identifier is wrong" do
      let(:identifier) { "THIS IS NO MOON!" }

      it { is_expected.to be_failure }
    end

    context "when user can't see wiki page" do
      let(:wiki_project_permissions) { %i[view_work_packages] }

      it { is_expected.to be_failure }
    end
  end
end
