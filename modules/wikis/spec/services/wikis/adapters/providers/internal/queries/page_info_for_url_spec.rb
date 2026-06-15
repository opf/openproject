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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::PageInfoForUrl,
               with_settings: { host_name: "openproject.example.com" } do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:input_data) { Wikis::Adapters::Input::PageInfoForUrl.build(url:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }
  let(:url) { "https://openproject.example.com/projects/#{project.identifier}/wiki/#{wiki_page.slug}" }

  let(:wiki_page) { create(:wiki_page) }
  let(:project) { wiki_page.project }
  let(:other_wiki_page) { create(:wiki_page) }
  let(:permissions) { %i[view_work_packages view_wiki_pages] }

  let(:user) { create(:user) }

  before do
    create(:member, project:, user:, roles: [create(:project_role, permissions:)])
  end

  it { is_expected.to be_success }

  it "resolves the wiki page" do
    page_info = subject.value!
    expect(page_info.title).to eq(wiki_page.title)
  end

  it "resolves the same URL as the input" do
    page_info = subject.value!

    # also validates that we parse URLs in the same format that we use to represent wiki pages
    expect(url).to end_with(page_info.href)
  end

  context "when using http URL scheme" do
    let(:url) { "http://openproject.example.com/projects/#{project.identifier}/wiki/#{wiki_page.slug}" }

    it "resolves the wiki page" do
      page_info = subject.value!
      expect(page_info.title).to eq(wiki_page.title)
    end
  end

  context "when URL has the wrong hostname" do
    let(:url) { "https://projectopen.example.com/projects/#{project.identifier}/wiki/#{wiki_page.slug}" }

    it { is_expected.to be_failure }
  end

  context "when URL has the wrong wiki page slug" do
    let(:url) { "https://openproject.example.com/projects/#{project.identifier}/wiki/not-#{wiki_page.slug}" }

    it { is_expected.to be_failure }
  end

  context "when URL has the wrong project identifier" do
    let(:url) { "https://openproject.example.com/projects/not-#{project.identifier}/wiki/#{wiki_page.slug}" }

    it { is_expected.to be_failure }
  end

  context "when user can't see wiki page" do
    let(:permissions) { %i[view_work_packages] }

    it { is_expected.to be_failure }
  end
end
