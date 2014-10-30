#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
    module WorkPackages
      class StatusesAPI < Grape::API
        class AvailableStatusesFormatter
          # this is an ugly hack to get the work package id for the path to self
          def work_package_id(env)
            env['rack.routing_args'][:id]
          end

          def call(object, env)
            if object.respond_to?(:to_json)
              object.to_json(work_package_id: work_package_id(env))
            else
              MultiJson.dump(object)
            end
          end
        end

        formatter 'hal+json', AvailableStatusesFormatter.new

        get '/available_statuses' do
          authorize({ controller: :work_packages, action: :update }, context: work_package.project)

          work_package.type = work_package.project.types.find_by_name(params[:type]) if params[:type]

          statuses = work_package.new_statuses_allowed_to(current_user)

          represented = ::API::V3::WorkPackages::AvailableStatusCollectionRepresenter.new(statuses)

          represented
        end
      end
    end
  end
end
