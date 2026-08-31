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

RSpec.describe WikiPages::CreateService do
  let(:instance) { described_class.new(user:) }
  let(:user) { create(:admin) }
  let(:wiki) { create(:wiki) }
  let(:internal_provider) { create(:internal_wiki_provider, enabled: true) }

  let(:work_package) { create(:work_package) }

  let(:reverse_link_finder) do
    Wikis::ReverseInlinePageLink.where(linkable: work_package, provider: internal_provider)
  end

  let(:attributes) do
    {
      wiki:,
      text:,
      title: "The test page"
    }
  end

  let(:text) do
    <<~TXT
      The Wiki page references work package ##{work_package.id}.
    TXT
  end

  subject { instance.call(**attributes) }

  before do
    wiki
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

  context "when a numeric reference is immediately followed by alphanumeric text" do
    # The numeric branch of WP_REF_RE has no trailing `(?!\w)` boundary —
    # historic behaviour matches `#13` inside `#13-blubb` and similar
    # shapes. Locked here so a future tightening of the boundary can't
    # silently strip reverse-links from existing wiki content.
    let(:text) { "Trailing: ##{work_package.id}abc" }

    it "still creates a reverse page link from the numeric prefix" do
      subject

      expect(reverse_link_finder.count).to eq(1)
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

  context "with a semantic-identifier reference",
          with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, :semantic) }
    let(:work_package) do
      create(:work_package, project:).tap do |wp|
        wp.allocate_and_register_semantic_id
        wp.reload
      end
    end

    context "when the reference uses the semantic identifier" do
      let(:text) { "See ##{work_package.identifier} for context." }

      it "creates a reverse page link" do
        subject

        expect(reverse_link_finder.count).to eq(1)
      end
    end

    context "when the semantic reference uses the ## widget syntax" do
      let(:text) { "Block: ###{work_package.identifier}." }

      it "creates a reverse page link" do
        subject

        expect(reverse_link_finder.count).to eq(1)
      end
    end

    context "when the semantic reference uses the ### widget syntax" do
      let(:text) { "Detailed: ####{work_package.identifier}." }

      it "creates a reverse page link" do
        subject

        expect(reverse_link_finder.count).to eq(1)
      end
    end

    context "when the project has been renamed and a historical alias is referenced" do
      let(:text) { "Historical: #OLD-#{work_package.sequence_number}." }

      before do
        WorkPackageSemanticAlias.create!(work_package:, identifier: "OLD-#{work_package.sequence_number}")
      end

      it "still creates a reverse page link" do
        subject

        expect(reverse_link_finder.count).to eq(1)
      end
    end

    context "when no work package matches the semantic reference" do
      let(:text) { "Missing: #GHOST-99." }

      it "does not create a link" do
        subject

        expect(Wikis::ReverseInlinePageLink.count).to eq(0)
      end
    end

    context "when the semantic identifier is followed by an alphanumeric word character" do
      let(:text) { "Boundary: ##{work_package.identifier}abc." }

      it "does not create a link" do
        subject

        expect(Wikis::ReverseInlinePageLink.count).to eq(0)
      end
    end

    context "when the body mixes a numeric and a semantic reference" do
      let(:numeric_work_package) { create(:work_package) }
      let(:text) do
        "Mixed: ##{numeric_work_package.id} and ##{work_package.identifier}."
      end

      it "creates a reverse page link per referenced work package" do
        subject

        wiki_page = WikiPage.first
        links = Wikis::ReverseInlinePageLink.where(provider: internal_provider, identifier: wiki_page.id)
        expect(links.pluck(:linkable_id)).to contain_exactly(numeric_work_package.id, work_package.id)
      end
    end

    context "when several reference shapes resolve to the same work package" do
      let(:text) do
        "Triple: ##{work_package.id}, ##{work_package.identifier}, #OLD-#{work_package.sequence_number}."
      end

      before do
        WorkPackageSemanticAlias.create!(work_package:, identifier: "OLD-#{work_package.sequence_number}")
      end

      it "creates a single reverse page link" do
        subject

        expect(reverse_link_finder.count).to eq(1)
        expect(reverse_link_finder.first.linkable).to eq(work_package)
      end
    end
  end

  context "with a semantic-shape reference in classic mode",
          with_settings: { work_packages_identifier: "classic" } do
    let(:text) { "See #PROJ-1 for context." }

    it "does not create a link" do
      subject

      expect(Wikis::ReverseInlinePageLink.count).to eq(0)
    end
  end
end
