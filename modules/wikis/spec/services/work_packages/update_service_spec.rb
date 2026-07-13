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

RSpec.describe WorkPackages::UpdateService do
  let(:instance) { described_class.new(user:, model: work_package) }
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }
  let(:provider) { create(:xwiki_provider) }
  let(:attributes) do
    {
      description: <<~TXT
        The work package description contains inline links to wiki pages (e.g. [[[#{provider.id}:abc]]]).
        It also contains links in a list:

        * [[[#{provider.id}:def]]]
        * [[[#{provider.id + 100}:ghi]]]
      TXT
    }
  end

  subject { instance.call(**attributes) }

  it "succeeds" do
    expect(subject).to be_success
  end

  it "creates inline page links for the existing provider" do
    subject

    expect(Wikis::InlinePageLink.where(provider:).count).to eq(2)
  end

  it "links wiki pages to the freshly created work package" do
    subject

    expect(Wikis::InlinePageLink.where(linkable: WorkPackage.first).count).to eq(2)
  end

  it "only creates links that had a valid provider id" do
    subject

    expect(Wikis::InlinePageLink.pluck(:identifier)).to contain_exactly("abc", "def")
  end

  context "when the same reference is made twice" do
    let(:attributes) do
      {
        description: <<~TXT
          * [[[#{provider.id}:abc]]]
          * [[[#{provider.id}:abc]]]
        TXT
      }
    end

    it "creates the link once" do
      subject

      expect(Wikis::InlinePageLink.pluck(:identifier)).to contain_exactly("abc")
    end
  end

  context "when other page links already exist" do
    before do
      create(:inline_wiki_page_link, provider:, linkable: work_package, identifier: "123")
    end

    it "deletes existing page links" do
      subject

      expect(Wikis::InlinePageLink.pluck(:identifier)).to contain_exactly("abc", "def")
    end

    context "and when the description does not change" do
      let(:attributes) { { subject: "This is a new subject" } }

      it "keeps existing page links" do
        subject

        expect(Wikis::InlinePageLink.pluck(:identifier)).to contain_exactly("123")
      end
    end
  end
end
