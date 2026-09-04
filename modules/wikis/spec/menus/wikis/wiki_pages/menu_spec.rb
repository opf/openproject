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

RSpec.describe Wikis::WikiPages::Menu do
  subject(:menu_entries) do
    described_class
      .new(params: ActionController::Parameters.new(params))
      .menu_items
      .first
      .children
  end

  let(:params) { {} }

  it "renders an entry per static query, linking with its query_id" do
    expect(menu_entries.map(&:title)).to eq [I18n.t("wikis.index.queries.all"),
                                             I18n.t("wikis.index.queries.main")]
    expect(menu_entries.map(&:href)).to eq ["/wiki_pages?query_id=all",
                                            "/wiki_pages?query_id=main"]
  end

  it "selects the all pages entry by default" do
    expect(menu_entries.map(&:selected)).to eq [true, false]
  end

  context "with the main query active" do
    let(:params) { { query_id: "main" } }

    it "selects the main pages entry" do
      expect(menu_entries.map(&:selected)).to eq [false, true]
    end
  end

  context "with an unknown query id" do
    let(:params) { { query_id: "everything" } }

    it "falls back to the all pages entry" do
      expect(menu_entries.map(&:selected)).to eq [true, false]
    end
  end
end
