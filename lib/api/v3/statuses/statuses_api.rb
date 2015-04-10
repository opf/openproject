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

require 'api/v3/statuses/status_collection_representer'
require 'api/v3/statuses/status_representer'

module API
  module V3
    module Statuses
      class StatusesAPI < ::API::OpenProjectAPI
        resources :statuses do
          before do
            authorize(:view_work_packages, global: true)

            @statuses = Status.all
          end

          get do
            StatusCollectionRepresenter.new(@statuses,
                                            @statuses.count,
                                            api_v3_paths.statuses)
          end

          route_param :id do
            before do
              status = Status.find(params[:id])
              @representer = StatusRepresenter.new(status)
            end

            get do
              @representer
            end
          end
        end
      end
    end
  end
end
