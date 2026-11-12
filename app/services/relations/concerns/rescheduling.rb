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

module Relations::Concerns
  module Rescheduling
    def reschedule_successor(relation)
      schedule_result = WorkPackages::SetScheduleService
                        .new(user:,
                             work_package: relation.successor,
                             switching_to_automatic_mode: switching_to_automatic_mode(relation))
                        .call

      # The schedule service does not save by itself. Dependent results must be saved.
      save_result = if schedule_result.success?
                      schedule_result.dependent_results
                                     .map(&:result)
                                     .filter(&:changed?)
                                     .all? { |work_package| work_package.save(validate: false) }
                    end

      schedule_result.success = save_result || false

      schedule_result
    end

    def switching_to_automatic_mode(relation)
      if should_switch_successor_to_automatic_mode?(relation)
        [relation.successor]
      else
        []
      end
    end

    def should_switch_successor_to_automatic_mode?(relation)
      relation.follows? \
        && creating? \
        && first_successor_relation?(relation) \
        && has_no_children?(relation.successor)
    end

    def creating?
      self.class.name.include?("Create")
    end

    def first_successor_relation?(relation)
      Relation.follows.of_successor(relation.successor)
                                   .not_of_predecessor(relation.predecessor).none?
    end

    def has_no_children?(work_package)
      !WorkPackage.exists?(parent: work_package)
    end
  end
end
