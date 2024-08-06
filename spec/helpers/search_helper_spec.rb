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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "search/index" do
  let(:project) { create(:project) }
  let(:scope) { "foobar" }

  before do
    allow(helper).to receive(:params).and_return(
      q: "foobar",
      all_words: "1",
      scope:
    )
    assign(:project, project)
  end

  describe "#highlight_tokens" do
    let(:maximum_length) { 1300 }

    subject(:highlighted_title) { helper.highlight_tokens title, tokens }

    context "with single token" do
      let(:tokens) { %w(token) }
      let(:title) { "This is a token." }
      let(:expected_title) { 'This is a <span class="search-highlight token-0">token</span>.' }

      it { is_expected.to eq expected_title }
    end

    context "with multiple tokens" do
      let(:tokens) { %w(token another) }
      let(:title) { "This is a token and another token." }
      let(:expected_title) do
        <<~TITLE.squish
          This is a <span class="search-highlight token-0">token</span>
          and <span class="search-highlight token-1">another</span>
          <span class="search-highlight token-0">token</span>.
        TITLE
      end

      it { is_expected.to eq expected_title }
    end

    context "with huge content" do
      let(:tokens) { %w(token) }
      let(:title) { "#{'1234567890' * 100} token " * 100 }
      let(:highlighted_token) { '<span class="search-highlight token-0">token</span>' }

      it { expect(highlighted_title).to include highlighted_token }

      it "does not exceed maximum length" do
        expect(highlighted_title.length).to be <= maximum_length
      end
    end

    context "with multibyte title" do
      let(:tokens) { %w(token) }
      let(:title) { "#{'й' * 200} token #{'й' * 200}" }
      let(:expected_title) do
        "#{'й' * 45} ... #{'й' * 44} <span class=\"search-highlight token-0\">token</span> #{'й' * 45} ... #{'й' * 44}"
      end

      it { is_expected.to eq expected_title }
    end
  end

  describe "#highlight_tokens_in_event" do
    let(:journal_notes) { "Journals notes" }
    let(:event_description) { "The description of the event" }
    let(:attachment_fulltext) { "The fulltext of the attachment" }
    let(:attachment_filename) { "attachment_filename.txt" }
    let(:journal) { build_stubbed(:work_package_journal, notes: journal_notes) }
    let(:event) do
      instance_double(WorkPackage,
                      last_journal: journal,
                      last_loaded_journal: journal,
                      event_description:,
                      attachment_ids: [42],
                      attachments: [build_stubbed(:attachment, filename: attachment_filename)]).tap do |e|
        scope = instance_double(ActiveRecord::Relation)

        allow(Attachment)
          .to receive(:where)
                .with(id: e.attachment_ids)
                .and_return(scope)

        allow(scope)
          .to receive(:pluck)
                .with(:fulltext)
                .and_return [attachment_fulltext]
      end
    end

    context "with the token in the journal notes" do
      let(:tokens) { %w(journals) }

      it "shows the text in the notes" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql '<span class="search-highlight token-0">Journals</span> notes'
      end
    end

    context "with the token in the description" do
      let(:tokens) { %w(description) }

      it "shows the text in the description" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql 'The <span class="search-highlight token-0">description</span> of the event'
      end
    end

    context "with the token in the description and empty journal notes" do
      let(:tokens) { %w(description) }
      let(:journal_notes) { "" }

      it "shows the text in the description" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql 'The <span class="search-highlight token-0">description</span> of the event'
      end
    end

    context "with the token in the attachment text" do
      let(:tokens) { %w(fulltext) }

      it "shows the text in the fulltext" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql 'The <span class="search-highlight token-0">fulltext</span> of the attachment'
      end
    end

    context "with the token in the attachment filename" do
      let(:tokens) { %w(filename) }

      it "shows the text in the fulltext" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql 'attachment_<span class="search-highlight token-0">filename</span>.txt'
      end
    end

    context "with the token in neither" do
      let(:tokens) { %w(bogus) }

      it "shows the description (without highlight)" do
        expect(helper.highlight_tokens_in_event(event, tokens))
          .to eql "The description of the event"
      end
    end
  end
end
