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

RSpec.describe ProjectQueries::Static do
  it "builds each static list with its intended filter" do
    expected_filters = {
      described_class::ACTIVE => ["active", OpenProject::Database::DB_VALUE_TRUE],
      described_class::MY => ["member_of", OpenProject::Database::DB_VALUE_TRUE],
      described_class::FAVORITED => ["favorited", OpenProject::Database::DB_VALUE_TRUE],
      described_class::ARCHIVED => ["active", OpenProject::Database::DB_VALUE_FALSE],
      described_class::ON_TRACK => ["project_status_code", Project.status_codes[:on_track]],
      described_class::OFF_TRACK => ["project_status_code", Project.status_codes[:off_track]],
      described_class::AT_RISK => ["project_status_code", Project.status_codes[:at_risk]],
      described_class::ACTIVE_PORTFOLIOS => ["active", OpenProject::Database::DB_VALUE_TRUE],
      described_class::MY_PORTFOLIOS => ["member_of", OpenProject::Database::DB_VALUE_TRUE],
      described_class::FAVORITED_PORTFOLIOS => ["favorited", OpenProject::Database::DB_VALUE_TRUE],
      described_class::ARCHIVED_PORTFOLIOS => ["active", OpenProject::Database::DB_VALUE_FALSE]
    }

    aggregate_failures do
      expected_filters.each do |query_id, (filter_name, value)|
        filter = described_class.query(query_id).filters.sole

        expect(filter).to have_attributes(name: filter_name.to_sym, operator: "=", values: [value.to_s])
      end
    end
  end
end
