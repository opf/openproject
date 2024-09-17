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

RSpec.describe Wiki do
  let(:project) { create(:project, disable_modules: "wiki") }
  let(:start_page) { "The wiki start page" }
  let(:wiki) { project.create_wiki start_page: }

  describe "creation" do
    it_behaves_like "acts_as_watchable included" do
      let(:model_instance) { create(:wiki) }
      let(:watch_permission) { :view_wiki_pages }
      let(:project) { model_instance.project }
    end

    describe "#create" do
      it "creates a wiki menu item on creation" do
        expect(wiki.wiki_menu_items).to be_one
      end

      it "sets the wiki menu item title to the name of the start page" do
        expect(wiki.wiki_menu_items.first.title).to eq(start_page)
      end

      it "requires a start_page" do
        wiki = project.create_wiki start_page: nil
        expect(wiki)
          .to be_new_record
      end
    end
  end

  describe "#start_page" do
    it "can be changed" do
      wiki.start_page = "Another start page"
      wiki.save

      expect(Wiki)
        .to exist(start_page: "Another start page")
    end
  end

  describe "#slug" do
    context "with an umlaut" do
      let(:wiki_page) { create(:wiki_page, wiki:, title: "Übersicht") }

      it "normalizes" do
        expect(wiki_page.slug).to eq "ubersicht"
      end
    end
  end

  describe "#find_page" do
    let(:title) { "Übersicht" }
    let!(:wiki_page) { create(:wiki_page, wiki:, title:) }
    let(:search_string) { "Übersicht" }

    subject { wiki.find_page(search_string) }

    context "when using the title" do
      it "finds the page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "when using the title in a different case" do
      let(:search_string) { "ÜBERSICHT" }

      it "finds the page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "for a date title" do
      let(:search_string) { '2009\\02\\09' }
      let(:title) { '2009\\02\\09' }

      it "finds the page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "for non latin characters" do
      let(:search_string) { "Этика менеджмента" }
      let(:title) { "Этика менеджмента" }

      it "finds the page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "with german default_language", with_settings: { default_language: "de" } do
      before do
        wiki_page.update_column(:slug, "uebersicht")
      end

      it "finds the page with the default_language slug title (Regression #38606)" do
        expect(subject)
          .to eq wiki_page
      end
    end
  end

  describe "#find_or_new_page" do
    let(:title) { "Übersicht" }
    let!(:wiki_page) { create(:wiki_page, wiki:, title:) }

    subject { wiki.find_or_new_page(search_string) }

    context "when using the title of an existing page" do
      let(:search_string) { title }

      it "returns that page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "when using the title in a different case" do
      let(:search_string) { "ÜBERSICHT" }

      it "finds the page" do
        expect(subject)
          .to eq wiki_page
      end
    end

    context "when using a different title" do
      let(:search_string) { title + title }

      it "returns a wiki page" do
        expect(subject)
          .to be_a WikiPage
      end

      it "returns an unpersisted record" do
        expect(subject)
          .to be_new_record
      end

      it "set the title of the new wiki page" do
        expect(subject.title)
          .to eq search_string
      end
    end
  end
end
