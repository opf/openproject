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

module API
  module V3
    module Reminders
      class RemindersByWorkPackageAPI < ::API::OpenProjectAPI
        resource :reminders do
          after_validation do
            authorize_in_project(:view_work_packages, project: @work_package.project)
          end

          helpers do
            def reminders
              @work_package.reminders.upcoming_and_visible_to(User.current)
            end

            def restrict_multiple_reminders
              if reminders.any?
                raise ::API::Errors::Conflict.new(
                  message: I18n.t("api_v3.errors.conflict.multiple_reminders_not_allowed")
                )
              end
            end
          end

          get do
            ReminderCollectionRepresenter.new(reminders,
                                              self_link: api_v3_paths.work_package_reminders(@work_package.id),
                                              current_user: User.current)
          end

          post(&API::V3::Utilities::Endpoints::Create.new(model: Reminder,
                                                          before_hook: ->(request:) { request.restrict_multiple_reminders },
                                                          params_modifier: ->(params) do
                                                            params.merge(remindable: @work_package,
                                                                         creator: User.current)
                                                          end).mount)
        end
      end
    end
  end
end
