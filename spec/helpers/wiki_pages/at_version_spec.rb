# -- copyright
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
# ++

require "spec_helper"

RSpec.describe WikiPages::AtVersion do
  let(:wiki_page) do
    build_stubbed(:wiki_page,
                  author: first_journal_user,
                  text: second_journal_text)
  end
  let(:first_journal) do
    build_stubbed(:wiki_page_journal,
                  user: first_journal_user,
                  journable: wiki_page,
                  version: 1,
                  data: build(:journal_wiki_page_journal,
                              text: first_journal_text))
  end
  let(:second_journal) do
    build_stubbed(:wiki_page_journal,
                  user: second_journal_user,
                  journable: wiki_page,
                  version: 2,
                  data: build(:journal_wiki_page_journal,
                              text: second_journal_text))
  end
  let(:first_journal_user) do
    build_stubbed(:user)
  end
  let(:second_journal_user) do
    build_stubbed(:user)
  end
  let(:first_journal_text) do
    "Lorem ipsum"
  end
  let(:second_journal_text) do
    "Ipsum lorem"
  end

  before do
    allow(wiki_page)
      .to receive(:journals)
            .and_return [first_journal, second_journal]
  end

  subject(:page_at_version) do
    described_class.new(wiki_page,
                        version)
  end

  describe "#author" do
    context "without a version" do
      let(:version) { nil }

      it "is the most recent journal`s user" do
        expect(page_at_version.author)
          .to eq second_journal_user
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is the first journal`s user" do
        expect(page_at_version.author)
          .to eq first_journal_user
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is the last journal`s user" do
        expect(page_at_version.author)
          .to eq second_journal_user
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the last journal`s user" do
        expect(page_at_version.author)
          .to eq second_journal_user
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is nil" do
        expect(page_at_version.author)
          .to be_nil
      end
    end

    context "with the version being less then 0" do
      let(:version) { -1 }

      it "is nil" do
        expect(page_at_version.author)
          .to be_nil
      end
    end
  end

  describe "#journals" do
    context "without a version" do
      let(:version) { nil }

      it "is the full set of journals" do
        expect(page_at_version.journals)
          .to contain_exactly(first_journal, second_journal)
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is only the first journal" do
        expect(page_at_version.journals)
          .to contain_exactly(first_journal)
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is the full set of journals" do
        expect(page_at_version.journals)
          .to contain_exactly(first_journal, second_journal)
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the full set of journals" do
        expect(page_at_version.journals)
          .to contain_exactly(first_journal, second_journal)
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is empty" do
        expect(page_at_version.journals)
          .to be_empty
      end
    end
  end

  describe "#lock_version" do
    context "without a version" do
      let(:version) { nil }

      it "is the page`s lock_version" do
        expect(page_at_version.lock_version)
          .to eq wiki_page.lock_version
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is the page`s lock_version" do
        expect(page_at_version.lock_version)
          .to eq wiki_page.lock_version
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is the page`s lock_version" do
        expect(page_at_version.lock_version)
          .to eq wiki_page.lock_version
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the page`s lock_version" do
        expect(page_at_version.lock_version)
          .to eq wiki_page.lock_version
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is the page`s lock_version" do
        expect(page_at_version.lock_version)
          .to eq wiki_page.lock_version
      end
    end
  end

  describe "#updated_at" do
    context "without a version" do
      let(:version) { nil }

      it "is the last journals`s updated_at" do
        expect(page_at_version.updated_at)
          .to eq second_journal.updated_at
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is the first journals`s updated_at" do
        expect(page_at_version.updated_at)
          .to eq first_journal.updated_at
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is the last journals`s updated_at" do
        expect(page_at_version.updated_at)
          .to eq second_journal.updated_at
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the last journals`s updated_at" do
        expect(page_at_version.updated_at)
          .to eq second_journal.updated_at
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is nil" do
        expect(page_at_version.updated_at)
          .to be_nil
      end
    end
  end

  describe "#version" do
    context "without a version" do
      let(:version) { nil }

      it "is the wiki_page`s version" do
        expect(page_at_version.version)
          .to eq wiki_page.version
      end
    end

    context "with the version provided" do
      let(:version) { 1 }

      it "is the provided version" do
        expect(page_at_version.version)
          .to eq version
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the highest possible version" do
        expect(page_at_version.version)
          .to eq 2
      end
    end

    context "with the version being 0" do
      let(:version) { 0 }

      it "is 0" do
        expect(page_at_version.version)
          .to eq 0
      end
    end

    context "with the version being less then 0" do
      let(:version) { -1 }

      it "is 0" do
        expect(page_at_version.version)
          .to eq 0
      end
    end
  end

  describe "#latest_version" do
    context "without a version" do
      let(:version) { nil }

      it "is the wiki_page`s version" do
        expect(page_at_version.latest_version)
          .to eq wiki_page.version
      end
    end

    context "with the version provided" do
      let(:version) { 1 }

      it "is the wiki_page`s version" do
        expect(page_at_version.latest_version)
          .to eq wiki_page.version
      end
    end
  end

  describe "#text" do
    context "without a version" do
      let(:version) { nil }

      it "is the last journals`s version" do
        expect(page_at_version.text)
          .to eq second_journal_text
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is the first journals`s text" do
        expect(page_at_version.text)
          .to eq first_journal_text
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is the last journals`s text" do
        expect(page_at_version.text)
          .to eq second_journal_text
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is the last journals`s text" do
        expect(page_at_version.text)
          .to eq second_journal_text
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is the wiki pages`s text" do
        expect(page_at_version.text)
          .to eq wiki_page.text
      end
    end
  end

  describe "#readonly?" do
    context "without a version" do
      let(:version) { nil }

      it "is false" do
        expect(page_at_version)
          .not_to be_readonly
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is true" do
        expect(page_at_version)
          .to be_readonly
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is false" do
        expect(page_at_version)
          .not_to be_readonly
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is false" do
        expect(page_at_version)
          .not_to be_readonly
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is true" do
        expect(page_at_version)
          .to be_readonly
      end
    end
  end

  describe "#current_version?" do
    context "without a version" do
      let(:version) { nil }

      it "is true" do
        expect(page_at_version)
          .to be_current_version
      end
    end

    context "with the version set to the first one" do
      let(:version) { 1 }

      it "is true" do
        expect(page_at_version)
          .not_to be_current_version
      end
    end

    context "with the version set to the last one" do
      let(:version) { 2 }

      it "is true" do
        expect(page_at_version)
          .to be_current_version
      end
    end

    context "with the version being larger then the current one" do
      let(:version) { 3 }

      it "is true" do
        expect(page_at_version)
          .to be_current_version
      end
    end

    context "with the version being less then 1" do
      let(:version) { 0 }

      it "is true" do
        expect(page_at_version)
          .not_to be_current_version
      end
    end
  end

  describe "#object" do
    context "without a version" do
      let(:version) { nil }

      it "returns the wiki page" do
        expect(page_at_version.object)
          .to eq wiki_page
      end
    end

    context "with a version" do
      let(:version) { 1 }

      it "returns the wiki page" do
        expect(page_at_version.object)
          .to eq wiki_page
      end
    end
  end

  describe "#respond_to?" do
    let(:version) { 1 }

    it "returns false for #to_model" do
      expect(page_at_version)
               .not_to respond_to(:to_model)
    end
  end
end
