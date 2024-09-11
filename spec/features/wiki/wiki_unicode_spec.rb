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

RSpec.describe "Wiki unicode title spec", :js do
  shared_let(:admin) { create(:admin) }
  let(:user) { admin }

  let(:project) { create(:project) }
  let(:wiki_page_1) do
    build(:wiki_page,
          title: '<script>alert("FOO")</script>')
  end
  let(:wiki_page_2) do
    build(:wiki_page,
          title: "Base de données")
  end
  let(:wiki_page_3) do
    build(:wiki_page,
          title: "Base_de_données")
  end

  let(:wiki_body) do
    <<-EOS
    [[Base de données]] should link to wiki_page_2

    [[Base_de_données]] should link to wiki_page_2

    [[base-de-donnees]] should link to wiki_page_2

    [[base-de-donnees-1]] should link to wiki_page_3 (slug duplicate!)

    [[<script>alert("FOO")</script>]]

    EOS
  end

  let(:expected_slugs) do
    %w(base-de-donnees base-de-donnees base-de-donnees base-de-donnees-1 alert-foo)
  end

  let(:expected_titles) do
    [
      "Base de données",
      "Base de données",
      "Base de données",
      "Base_de_données",
      '<script>alert("FOO")</script>'
    ]
  end

  before do
    login_as(user)

    project.wiki.pages << wiki_page_1
    project.wiki.pages << wiki_page_2
    project.wiki.pages << wiki_page_3

    project.wiki.save!

    visit project_wiki_path(project, :wiki)

    # Set value
    find(".ck-content").base.send_keys(wiki_body)
    click_button "Save"

    expect(page).to have_css(".title-container h2", text: "Wiki")
    expect(page).to have_css("a.wiki-page", count: 5)
  end

  it "shows renders correct links" do
    expected_titles.each_with_index do |title, i|
      visit project_wiki_path(project, :wiki)

      expect(page).to have_css("div.wiki-content")
      target_link = all("div.wiki-content a.wiki-page")[i]

      expect(target_link.text).to eq(title)
      expect(target_link[:href]).to match("/wiki/#{expected_slugs[i]}")
      target_link.click

      expect(page).to have_css(".title-container h2", text: title)
    end
  end
end
