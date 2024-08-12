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

RSpec.describe API::V3::WorkPackages::WorkPackageEagerLoadingWrapper, "cost eager loading", type: :model do
  let(:project) do
    work_package.project
  end
  let(:role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           view_cost_entries
                           view_cost_rates
                           view_time_entries
                           log_time
                           log_costs
                           view_hourly_rates])
  end
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end

  let(:cost_type) do
    create(:cost_type)
  end
  let(:work_package) do
    create(:work_package)
  end
  let(:cost_entry1) do
    create(:cost_entry,
           cost_type:,
           user:,
           work_package:,
           project:)
  end
  let(:cost_entry2) do
    create(:cost_entry,
           cost_type:,
           user:,
           work_package:,
           project:)
  end
  let(:time_entry1) do
    create(:time_entry,
           user:,
           project:,
           work_package:)
  end
  let(:time_entry2) do
    create(:time_entry,
           user:,
           project:,
           work_package:)
  end
  let(:user_rates) do
    create(:hourly_rate,
           user:,
           project:)
  end
  let(:cost_rate) do
    create(:cost_rate,
           cost_type:)
  end

  context "combining core's and cost's eager loading" do
    let(:scope) do
      API::V3::WorkPackages::WorkPackageEagerLoadingWrapper.wrap([work_package.id], user)
    end

    before do
      login_as(user)

      user_rates
      project.reload
      cost_rate
      cost_entry1
      cost_entry2
      time_entry1
      time_entry2
    end

    it "correctly calculates spent time" do
      expect(scope.to_a.first.hours).to eql time_entry1.hours + time_entry2.hours
    end

    it "correctly calculates labor costs" do
      expect(scope.first.labor_costs).to eql (user_rates.rate * (time_entry1.hours + time_entry2.hours)).to_f
    end

    it "correctly calculates material costs" do
      expect(scope.first.material_costs).to eql (cost_entry1.costs + cost_entry2.costs).to_f
    end
  end
end
