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

RSpec.describe Wikis::Adapters::Providers::Internal::Queries::ReferencingPages do
  subject { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:input_data) { Wikis::Adapters::Input::ReferencingPages.build(linkable:).value! }
  let(:auth_strategy) { provider.auth_strategy_for(user).value! }
  let(:linkable) { create(:work_package) }

  let(:wiki_page) { create(:wiki_page) }
  let(:wiki_project) { wiki_page.project }
  let(:wiki_project_permissions) { %i[view_wiki_pages] }

  let(:reverse_page_links) do
    [
      create(:reverse_inline_wiki_page_link, provider:, linkable:, identifier: wiki_page.id)
    ]
  end

  let(:user) { create(:user) }

  before do
    create(:member, project: wiki_project,
                    user:,
                    roles: [create(:project_role, permissions: wiki_project_permissions)])

    reverse_page_links.each(&:save!)
  end

  it { is_expected.to be_success }

  it "returns pages indicated by reverse links" do
    results = subject.value!
    expect(results).to all(be_success)
    infos = results.map(&:value!)
    expect(infos.map(&:title)).to contain_exactly(wiki_page.title)
  end

  context "when there are no reverse links" do
    let(:reverse_page_links) { [] }

    it { is_expected.to be_success }

    it "returns an empty result" do
      expect(subject.value!).to eq([])
    end
  end

  context "when there are reverse links to other linkables" do
    let(:reverse_page_links) do
      [
        create(:reverse_inline_wiki_page_link, provider:, identifier: wiki_page.id)
      ]
    end

    it "does not return them" do
      expect(subject.value!).to eq([])
    end
  end

  context "when user can't see linked wiki page" do
    let(:wiki_project_permissions) { %i[] }

    it { is_expected.to be_success }

    it "returns a result with a failure" do
      results = subject.value!
      expect(results).to all(be_failure)
      errors = results.map(&:failure)
      expect(errors.map(&:code)).to contain_exactly(:not_found)
    end
  end
end
