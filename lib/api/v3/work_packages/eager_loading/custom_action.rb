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
        class CustomAction < Base
          def apply(work_package)
            applicable_actions = custom_actions.select do |action|
              action.conditions_fulfilled?(work_package, User.current)
            end

            work_package.custom_actions = applicable_actions
          end

          def self.module
            CustomActionAccessor
          end

          private

          def custom_actions
            @custom_actions ||= ::CustomAction
                                .available_conditions
                                .inject(::CustomAction.all) do |scope, condition|
              scope.merge(condition.custom_action_scope(work_packages, User.current))
            end
          end

          module CustomActionAccessor
            extend ActiveSupport::Concern

            included do
              attr_writer :custom_actions

              # Hiding the work_package's own custom_actions method
              # to profit from the eager loaded actions
              def custom_actions(_user)
                @custom_actions
              end
            end
          end
        end
      end
    end
  end
end
