#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      module CustomActions
        class CustomActionsWrapper < SimpleDelegator
          attr_writer :custom_actions
          attr_accessor :work_package

          def initialize(work_package, actions)
            super(work_package)
            self.work_package = work_package
            self.custom_actions = actions
          end
          private_class_method :new

          # Hiding the work_package's own custom_actions method
          # to profit from the eager loaded actions
          def custom_actions(_user)
            @custom_actions
          end

          def self.wrap(work_packages, user)
            actions = CustomAction
                      .available_conditions
                      .inject(CustomAction.all) do |scope, condition|

              scope.merge(condition.custom_action_scope(work_packages, user))
            end

            work_packages.map do |work_package|
              applicable_actions = actions.select do |action|
                action.conditions_fulfilled?(work_package, user)
              end

              new(work_package, applicable_actions)
            end
          end
        end
      end
    end
  end
end
