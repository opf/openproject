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

RSpec.describe Queries::Wikis::WikiPages::WikiPageQuery do
  subject(:query) { described_class.new(user:) }

  let(:user) { create(:user) }

  describe "#results" do
    let(:role) { create(:project_role, permissions: [:view_wiki_pages]) }
    let(:project) { create(:project, :with_internal_wiki, members: { user => role }) }
    let(:wiki) { project.wiki }
    let!(:older_main_page) { create(:wiki_page, wiki:) }
    let!(:newer_main_page) { create(:wiki_page, wiki:) }
    let!(:sub_page) { create(:wiki_page, wiki:, parent: older_main_page) }
    let!(:invisible_page) { create(:wiki_page, wiki: create(:project, :with_internal_wiki).wiki) }

    before do
      older_main_page.update_column(:updated_at, 2.days.ago)
      newer_main_page.update_column(:updated_at, 1.day.ago)
      sub_page.update_column(:updated_at, 1.hour.ago)
    end

    it "returns all pages of projects visible to the given user, most recently edited first" do
      expect(query.results).to eq [sub_page, newer_main_page, older_main_page]
    end

    it "does not return pages of projects the given user cannot see" do
      expect(query.results).not_to include(invisible_page)
      expect(described_class.new(user: create(:user)).results).to be_empty
    end

    it "selects the number of direct sub-pages alongside each page" do
      expect(query.results.map(&:sub_pages_count)).to eq [0, 0, 1]
    end

    context "with the main query" do
      before { query.query_id = "main" }

      it "returns main pages only" do
        expect(query.results).to eq [newer_main_page, older_main_page]
      end
    end
  end

  describe "#query_id" do
    it "defaults to all" do
      expect(query.query_id).to eq "all"
    end

    it "accepts registered static query ids" do
      query.query_id = "main"
      expect(query.query_id).to eq "main"
    end

    it "falls back to the default for unknown values" do
      query.query_id = "everything"
      expect(query.query_id).to eq "all"
    end
  end

  describe "#name" do
    it "returns the localized name of the selected static query" do
      expect(query.name).to eq I18n.t("wikis.index.queries.all")

      query.query_id = "main"
      expect(query.name).to eq I18n.t("wikis.index.queries.main")
    end
  end

  describe ".static_queries" do
    it "returns one query per registered static query, in sidebar order" do
      expect(described_class.static_queries.map(&:query_id)).to eq %w[all main]
    end
  end
end
