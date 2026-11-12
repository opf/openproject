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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe WikiHelper do
  describe "#breadcrumb_for_page" do
    let(:project)   { create(:project, name: "World Cities") }
    let(:wiki)      { create(:wiki, project:) }

    context "with one page" do
      let(:wiki_page) { create(:wiki_page, wiki:, title: "New York 🗽") }

      it "returns breadcrumb items" do
        expect(helper.breadcrumb_for_page(project, wiki_page)).to eq(
          [
            { href: project_overview_path(project),             text: "World Cities" },
            { href: toc_project_wiki_path(project, wiki_page),  text: "Wiki" },
            "New York 🗽"
          ]
        )
      end
    end

    context "with a hierarchy of pages" do
      let(:wiki_page) { create(:wiki_page, wiki:, title: "Nightlife 🪩", parent: city) }

      let(:city)      { create(:wiki_page, wiki:, title: "Berlin 🍩", parent: country) }
      let(:country)   { create(:wiki_page, wiki:, title: "Germany 🇩🇪", parent: continent) }
      let(:continent) { create(:wiki_page, wiki:, title: "Europe 🇪🇺") }

      it "returns breadcrumb items" do
        expect(helper.breadcrumb_for_page(project, wiki_page)).to eq(
          [
            { href: project_overview_path(project),             text: "World Cities" },
            { href: toc_project_wiki_path(project, wiki_page),  text: "Wiki" },
            { href: project_wiki_path(project, continent),      text: "Europe 🇪🇺" },
            { href: project_wiki_path(project, country),        text: "Germany 🇩🇪" },
            { href: project_wiki_path(project, city),           text: "Berlin 🍩" },
            "Nightlife 🪩"
          ]
        )
      end
    end
  end
end
