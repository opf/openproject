#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module TimeEntries
      class TimeEntriesAPI < ::API::OpenProjectAPI
        resources :time_entries do
          route_param :id do
            before do
              @time_entries = TimeEntry.find(params[:id])

              authorized_for_time_entry?(@time_entries)
            end

            helpers do
              def authorized_for_time_entry?(time_entries)
                Rails.logger.warn "time_entries_api.rb - authorized_for"
                project = time_entries.project

                permissions = [:view_work_packages, :view_time_entries]

                authorize_any(permissions, projects: project, user: current_user)
              end

              def authorized_to_add_time_entry?(time_entries)
                project = time_entries.project

                permissions = [:log_time]

                authorize_any(permissions, projects: project, user: current_user)
              end
            end

            get do
              res = TimeEntryRepresenter.new(@time_entries, current_user: current_user)
              Rails.logger.warn "res: #{res}"
              res
            end

            #mount ::API::V3::TimeEntries::TimeEntriesByProjectAPI
          end
        end
      end
    end
  end
end
