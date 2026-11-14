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

require "spec_helper"

RSpec.describe Queries::WorkPackageCustomFields::Filters::FieldFormatFilter do
  subject(:filter) { Queries::WorkPackageCustomFields::WorkPackageCustomFieldQuery.new.filter_for(:field_format) }

  it "offers the formats of work package custom fields, including enterprise ones" do
    expect(filter.allowed_values.map(&:last)).to include("list", "hierarchy", "weighted_item_list")
  end

  it "does not offer formats limited to other custom fields" do
    expect(filter.allowed_values.map(&:last)).not_to include("calculated_value")
  end
end
