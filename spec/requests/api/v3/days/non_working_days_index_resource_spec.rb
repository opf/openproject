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

require "spec_helper"
require "services/work_packages/shared/shared_examples_days"

RSpec.describe API::V3::Days::NonWorkingDaysAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:filters) { [] }

  current_user { user }

  before do
    get api_v3_paths.path_for :days_non_working, filters:
  end

  context "for an admin user", :non_working_days_from_this_and_next_year do
    let(:user) { build(:admin) }

    it_behaves_like "API V3 collection response", 2, 2, "NonWorkingDay"

    context "when filtering by date" do
      let(:filters) do
        [{ date: { operator: "<>d",
                   values: [first_of_may.date.beginning_of_month.iso8601, new_year_day.date.iso8601] } }]
      end

      it_behaves_like "API V3 collection response", 3, 3, "NonWorkingDay"
    end
  end
end
