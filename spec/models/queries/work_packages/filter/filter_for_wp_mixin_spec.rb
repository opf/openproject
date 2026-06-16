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

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::FilterForWpMixin do
  describe "#autocomplete_options" do
    context "on a list-type filter (e.g. ParentFilter)" do
      subject(:filter) { Queries::WorkPackages::Filter::ParentFilter.create!(name: :parent) }

      it "returns the WP autocompleter config so FilterForm routes the filter to AutocompleteForm" do
        # The candidate set is too large to enumerate (`allowed_values`
        # intentionally raises), so the filter must render as a server-side
        # autocompleter against the work_packages resource. Matches the
        # Angular `op-filter-searchable-multiselect-value` behaviour.
        expect(filter.autocomplete_options).to eq(
          component: "opce-autocompleter",
          resource: "work_packages",
          searchKey: "typeahead"
        )
      end
    end

    context "on a relation-type filter (RelatableFilter)" do
      subject(:filter) { Queries::WorkPackages::Filter::RelatableFilter.create!(name: :relatable) }

      it "returns an empty hash so the FilterForm dispatch falls through to a non-autocomplete input" do
        expect(filter.type).to eq(:relation)
        expect(filter.autocomplete_options).to eq({})
      end
    end

    context "on a search-type filter (SearchFilter)" do
      subject(:filter) { Queries::WorkPackages::Filter::SearchFilter.create!(name: :search) }

      it "returns an empty hash so the FilterForm dispatch falls through to a text input" do
        expect(filter.type).to eq(:search)
        expect(filter.autocomplete_options).to eq({})
      end
    end
  end
end
