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

RSpec.describe WikiPages::UpdateService do
  let(:instance) { described_class.new(user:, model: wiki_page) }
  let(:user) { create(:admin) }
  let(:wiki_page) { create(:wiki_page) }
  let(:internal_provider) { create(:internal_wiki_provider, enabled: true) }

  let(:work_package) { create(:work_package) }

  let(:reverse_link_finder) do
    Wikis::ReverseInlinePageLink.where(linkable: work_package, provider: internal_provider)
  end

  let(:attributes) { { text: } }

  let(:text) do
    <<~TXT
      The Wiki page references work package ##{work_package.id}.
    TXT
  end

  subject { instance.call(**attributes) }

  before do
    internal_provider
  end

  it "succeeds" do
    expect(subject).to be_success
  end

  it "creates a reverse page link" do
    subject

    expect(reverse_link_finder.count).to eq(1)
  end

  it "references the created wiki page" do
    subject

    expect(Wikis::ReverseInlinePageLink.first.identifier).to eq(WikiPage.first.id.to_s)
  end

  context "when the same reference is made twice" do
    let(:text) do
      <<~TXT
        The Wiki page references work package ##{work_package.id} + ##{work_package.id}.
      TXT
    end

    it "creates the link once" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when the reference is the only content (no suffix or prefix)" do
    let(:text) { "##{work_package.id}" }

    it "creates a reverse page link" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when the reference is parenthesized" do
    let(:text) { "(##{work_package.id})" }

    it "creates a reverse page link" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when the reference is escaped" do
    let(:text) { "!##{work_package.id}" }

    it "does not create a link" do
      subject

      expect(Wikis::ReverseInlinePageLink.count).to eq(0)
    end
  end

  context "when the reference is made using ## syntax" do
    let(:text) do
      <<~TXT
        The Wiki page references work package ###{work_package.id}.
      TXT
    end

    it "creates a reverse page link" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when the reference is made using ### syntax" do
    let(:text) do
      <<~TXT
        The Wiki page references work package ####{work_package.id}.
      TXT
    end

    it "creates a reverse page link" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when the reference is made inside a <mention> element" do
    let(:text) do
      <<~TXT
        The Wiki page references work package <mention class="mention" data-id="#{work_package.id}" data-type="work_package" data-text="##{work_package.id}">##{work_package.id}</mention>.
      TXT
    end

    it "creates a reverse page link" do
      subject

      expect(reverse_link_finder.count).to eq(1)
    end
  end

  context "when there is a link with a fragment" do
    let(:text) do
      <<~TXT
        And a weird [link](https://example.com/##{work_package.id}-blubb).
      TXT
    end

    it "does not create a link" do
      subject

      expect(Wikis::ReverseInlinePageLink.count).to eq(0)
    end
  end

  context "when the internal provider is disabled" do
    let(:internal_provider) { create(:internal_wiki_provider, enabled: false) }

    it "does not create a link" do
      subject

      expect(Wikis::ReverseInlinePageLink.count).to eq(0)
    end
  end

  context "when a work package with the given ID does not exist" do
    let(:text) do
      <<~TXT
        The Wiki page references work package ##{work_package.id + 10}.
      TXT
    end

    it "does not create a link" do
      subject

      expect(Wikis::ReverseInlinePageLink.count).to eq(0)
    end
  end

  context "when other page links already exist" do
    let(:fake_wp_id) { work_package.id + 100 }

    before do
      create(
        :reverse_inline_wiki_page_link,
        provider: internal_provider,
        linkable_type: WorkPackage.name,
        linkable_id: fake_wp_id,
        identifier: wiki_page.id
      )
    end

    it "deletes existing page links" do
      subject

      expect(Wikis::ReverseInlinePageLink.pluck(:linkable_id)).to contain_exactly(work_package.id)
    end

    context "and when the description does not change" do
      let(:attributes) { { title: "This is a new subject" } }

      it "keeps existing page links" do
        subject

        expect(Wikis::ReverseInlinePageLink.pluck(:linkable_id)).to contain_exactly(fake_wp_id)
      end
    end
  end

  describe "replacing the attachments" do
    let(:project) { create(:project) }
    let(:wiki_page) { create(:wiki_page, wiki: project.wiki, author: user) }
    let(:user) do
      create(:user,
             member_with_permissions: { project => %i[view_wiki_pages edit_wiki_pages] })
    end

    let!(:old_attachment) { create(:attachment, container: wiki_page) }
    let!(:other_users_attachment) { create(:attachment, container: nil, author: create(:user)) }
    let!(:new_attachment) { create(:attachment, container: nil, author: user) }

    it "rejects other user's pending attachments and replaces attachments owned by the user" do
      result = instance.call(attachment_ids: [other_users_attachment.id])

      expect(result).to be_failure
      expect(result.errors.symbols_for(:attachments)).to contain_exactly(:does_not_exist)

      expect(wiki_page.attachments.reload).to contain_exactly(old_attachment)
      expect(other_users_attachment.reload.container).to be_nil

      result = instance.call(attachment_ids: [new_attachment.id])

      expect(result).to be_success
      expect(wiki_page.attachments.reload).to contain_exactly(new_attachment)
      expect(new_attachment.reload.container).to eql wiki_page

      expect(Attachment.find_by(id: old_attachment.id)).to be_nil
    end
  end
end
