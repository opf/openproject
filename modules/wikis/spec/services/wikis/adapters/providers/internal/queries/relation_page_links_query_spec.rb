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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::RelationPageLinks do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:input_data) { Wikis::Adapters::Input::RelationPageLinks.build(linkable: work_package).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }

  let(:wiki_page) { create(:wiki_page) }
  let(:project) { wiki_page.project }
  let(:work_package) { create(:work_package) }
  let(:permissions) { %i[view_wiki_pages] }
  let(:link_to_existing_page) do
    create(:relation_wiki_page_link, provider:, linkable: work_package, identifier: wiki_page.id.to_s)
  end
  let(:link_to_non_existing_page) do
    create(:relation_wiki_page_link, provider:, linkable: work_package, identifier: "THIS IS NO MOON")
  end

  let(:user) { create(:user) }

  before do
    create(:member, project:, user:, roles: [create(:project_role, permissions:)])

    link_to_existing_page
    link_to_non_existing_page
  end

  it { is_expected.to be_success }

  it "returns aggregates with the page info results of the wiki pages and the page links" do
    result = subject.value!
    expect(result.size).to eq(2)
    expect(result[0]).to be_a(Wikis::Adapters::Results::PageLinkAggregate)
    expect(result[0].page_info_result.value!.title).to eq(wiki_page.title)
    expect(result[0].page_info_result.value!.href).to eq("/projects/#{project.identifier}/wiki/#{wiki_page.slug}")
    expect(result[0].page_link).to eq(link_to_existing_page)

    expect(result[1]).to be_a(Wikis::Adapters::Results::PageLinkAggregate)
    expect(result[1].page_info_result).to be_failure
    expect(result[1].page_info_result.failure.code).to eq(:not_found)
    expect(result[1].page_link).to eq(link_to_non_existing_page)
  end

  context "when user can't see wiki pages" do
    let(:permissions) { [] }

    it "returns an array of results with `not_found`" do
      result = subject.value!
      expect(result.size).to eq(2)

      expect(result[0].page_info_result).to be_failure
      expect(result[0].page_info_result.failure.code).to eq(:not_found)
      expect(result[0].page_link).to eq(link_to_existing_page)
      expect(result[1].page_info_result).to be_failure
      expect(result[1].page_info_result.failure.code).to eq(:not_found)
      expect(result[1].page_link).to eq(link_to_non_existing_page)
    end
  end
end
