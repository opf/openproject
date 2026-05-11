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

module API
  module V3
    module WorkPackages
      module EagerLoading
        class Automation < Base
          def apply(work_package)
            applicable_automations = automations.select do |automation|
              automation.conditions_fulfilled?(work_package, User.current)
            end

            work_package.automations = applicable_automations
          end

          def self.module
            AutomationAccessor
          end

          private

          def automations
            @automations ||= ::Automation
                             .available_conditions
                             .inject(::Automation.with_manual_trigger.includes(:triggers)) do |scope, condition|
              scope.merge(condition.automation_scope(work_packages, User.current))
            end
          end

          module AutomationAccessor
            extend ActiveSupport::Concern

            included do
              attr_writer :automations

              # Hiding the work_package's own automations method
              # to profit from the eager loaded automations
              def automations(_user)
                @automations
              end

              # API compatibility for /api/v3/custom_actions
              def custom_actions(user) = automations(user)
            end
          end
        end
      end
    end
  end
end
