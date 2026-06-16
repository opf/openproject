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

RSpec.describe Wikis::Adapters::Providers::Internal::Commands::CreatePage do
  subject(:result) { described_class.new(model: provider).call(input_data:, auth_strategy:) }

  let(:provider) { create(:internal_wiki_provider) }
  let(:auth_strategy) { Wikis::Adapters::Input::AuthStrategy.build(key: :internal, user:, provider:).value! }
  let(:input_data) { Wikis::Adapters::Input::CreatePage.build(title:, parent_identifier:).value! }
  let(:user) { create(:user) }

  let(:title) { "A page automatically created during a create_page test" }
  let(:parent_identifier) { existing_page.id.to_s }

  let(:existing_page) { create(:wiki_page) }
  let(:project) { existing_page.project }
  let(:permissions) { %i[view_wiki_pages edit_wiki_pages] }

  before do
    create(:member, project:, user:, roles: [create(:project_role, permissions:)])
  end

  it { is_expected.to be_success }

  it "successfully creates a page" do
    expect { subject }.to change(WikiPage, :count).by(1)

    expect(WikiPage.last.title).to eq(title)
  end

  it "makes the page a child of the intended parent" do
    subject
    expect(WikiPage.last.parent).to eq(existing_page)
  end

  it "returns the page info of the created page" do
    expect(subject.value!.identifier).to eq(WikiPage.last.id.to_s)
    expect(subject.value!.title).to eq(title)
  end

  context "when the parent does not exist" do
    let(:parent_identifier) { (existing_page.id * 10).to_s }

    it "returns a :not_found error" do
      expect(result).to be_failure
      expect(result.failure.code).to eq(:not_found)
    end

    it "does not create a page" do
      expect { subject }.not_to change(WikiPage, :count)
    end
  end

  context "when the parent is not visible to the user" do
    let(:permissions) { %i[edit_wiki_pages] }

    it "returns a :not_found error" do
      expect(result).to be_failure
      expect(result.failure.code).to eq(:not_found)
    end

    it "does not create a page" do
      expect { subject }.not_to change(WikiPage, :count)
    end
  end

  context "when user is not allowed to create wiki pages" do
    let(:permissions) { %i[view_wiki_pages] }

    it "returns a :forbidden error" do
      expect(result).to be_failure
      expect(result.failure.code).to eq(:forbidden)
    end

    it "does not create a page" do
      expect { subject }.not_to change(WikiPage, :count)
    end
  end
end
