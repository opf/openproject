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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe PlaceholderUsers::CriteriaFilterComponent, type: :component do
  include QuickFilterHelpers

  let(:query) { Queries::PlaceholderUsers::PlaceholderUserQuery.new }

  subject(:component) { described_class.new(query:) }

  before { render_inline(component) }

  it "offers the unfiltered state alongside the two criteria states" do
    expect(page).to have_css("a", count: 3)
    expect(page).to have_text(I18n.t(:label_all_uppercase))
    expect(page).to have_text(I18n.t(:label_with_criteria))
    expect(page).to have_text(I18n.t(:label_without_criteria))
  end

  it "marks the unfiltered item as selected while the filter is inactive" do
    expect(page).to have_css("[aria-current='true']", count: 1)
    expect(page).to have_css("[aria-current='true']", text: I18n.t(:label_all_uppercase))
  end

  it "links the unfiltered item to the index without the criteria filter" do
    expect(page.find("a", text: I18n.t(:label_all_uppercase))[:href]).not_to include("has_user_filter")
  end

  context "when filtering for placeholders with criteria" do
    let(:query) { Queries::PlaceholderUsers::PlaceholderUserQuery.new.where("has_user_filter", "=", ["t"]) }

    it "moves the selection onto that item" do
      expect(page).to have_css("[aria-current='true']", count: 1)
      expect(page).to have_css("[aria-current='true']", text: I18n.t(:label_with_criteria))
    end

    it "keeps the unfiltered item as the way back" do
      expect(page.find("a", text: I18n.t(:label_all_uppercase))[:href]).not_to include("has_user_filter")
    end
  end
end
