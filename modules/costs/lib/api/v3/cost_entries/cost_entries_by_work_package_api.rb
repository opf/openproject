#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'api/v3/cost_types/cost_type_representer'

module API
  module V3
    module CostEntries
      class CostEntriesByWorkPackageAPI < ::API::OpenProjectAPI
        after_validation do
          authorize_any([:view_cost_entries, :view_own_cost_entries],
                        projects: @work_package.project)
          @cost_helper = ::OpenProject::Costs::AttributesHelper.new(@work_package, current_user)
        end

        resources :cost_entries do
          get do
            path = api_v3_paths.cost_entries_by_work_package(@work_package.id)
            cost_entries = @cost_helper.cost_entries
            CostEntryCollectionRepresenter.new(cost_entries,
                                               cost_entries.count,
                                               path,
                                               current_user: current_user)
          end
        end

        resources :summarized_costs_by_type do
          get do
            WorkPackageCostsByTypeRepresenter.new(@work_package, current_user: current_user)
          end
        end
      end
    end
  end
end
