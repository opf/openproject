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

RSpec.describe WikiRedirect do
  let(:wiki) { create(:wiki) }
  let(:wiki_page) { create(:wiki_page, wiki:, title: "Original title") }

  context "when renaming the page" do
    before do
      wiki_page.title = "New title"
      wiki_page.save
    end

    it "creates a redirect" do
      expect(wiki.redirects)
        .to exist(title: "original-title")
    end

    it "allows to still find the page via the original title" do
      expect(wiki.find_page("Original title"))
        .to eq wiki_page
    end

    it "allows to still find the page via the original title even with a different case" do
      expect(wiki.find_page("ORIGINAL title"))
        .to eq wiki_page
    end
  end

  context "when renaming twice" do
    before do
      wiki_page.title = "New old title"
      wiki_page.save

      wiki_page.title = "New title"
      wiki_page.save
    end

    it "allows to still find the page via the original title" do
      expect(wiki.find_page("Original title"))
        .to eq wiki_page
    end

    it "allows to still find the page via the intermediate title" do
      expect(wiki.find_page("New old title"))
        .to eq wiki_page
    end

    it "allows to still find the page via the current title" do
      expect(wiki.find_page("New title"))
        .to eq wiki_page
    end
  end

  context "when reversing the rename" do
    before do
      wiki_page.title = "New title"
      wiki_page.save

      wiki_page.title = "Original title"
      wiki_page.save
    end

    it "allows to find the page via the original title" do
      expect(wiki.find_page("Original title"))
        .to eq wiki_page
    end

    it "allows to still find the page via the intermediate title" do
      expect(wiki.find_page("New title"))
        .to eq wiki_page
    end
  end

  context "when an equally named redirect already exists" do
    before do
      WikiRedirect.create!(wiki:, title: "an-old-page", redirects_to: "other-page")

      wiki_page.title = "An old page"
      wiki_page.save
    end

    it "overwrite the old redirect" do
      expect(wiki.find_page("An old page"))
        .to eq wiki_page
    end
  end

  it "is removed when deleting the page" do
    redirect = WikiRedirect.create(wiki:, title: "an-old-page", redirects_to: wiki_page.slug)

    wiki_page.destroy
    expect(WikiRedirect)
      .not_to exist(id: redirect.id)
  end
end
