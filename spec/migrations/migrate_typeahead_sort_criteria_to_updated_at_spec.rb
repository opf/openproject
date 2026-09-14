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
require Rails.root.join("db/migrate/20260727111530_migrate_typeahead_sort_criteria_to_updated_at")

RSpec.describe MigrateTypeaheadSortCriteriaToUpdatedAt, type: :model do
  shared_let(:typeahead_only) { create(:query, sort_criteria: [["typeahead", "desc"]]) }
  shared_let(:typeahead_with_other_criteria) { create(:query, sort_criteria: [["typeahead", "asc"], ["subject", "asc"]]) }
  shared_let(:unrelated_query) { create(:query, sort_criteria: [["subject", "asc"]]) }
  shared_let(:already_has_updated_at) { create(:query, sort_criteria: [["updated_at", "asc"], ["typeahead", "desc"]]) }

  it "migrates typeahead sort criteria to updated_at desc, leaving everything else alone" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

    expect(typeahead_only.reload.sort_criteria).to eq([["updated_at", "desc"]])
    expect(typeahead_with_other_criteria.reload.sort_criteria).to eq([["updated_at", "desc"], ["subject", "asc"]])
    expect(unrelated_query.reload.sort_criteria).to eq([["subject", "asc"]])
    # The pre-existing updated_at entry wins over the typeahead-derived replacement (first occurrence kept).
    expect(already_has_updated_at.reload.sort_criteria).to eq([["updated_at", "asc"]])
  end
end
