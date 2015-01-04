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

# Root class of the API v3
# This is the place for all API v3 wide configuration, helper methods, exceptions
# rescuing, mounting of differnet API versions etc.

module API
  module V3
    class Root < ::Cuba
      define do
        res.headers['Content-Type'] = 'application/json; charset=utf-8'

        on 'activities' do
          run ::API::V3::Activities::ActivitiesAPI
        end

        on 'attachments' do
          run ::API::V3::Attachments::AttachmentsAPI
        end

        on 'priorities' do
          run ::API::V3::Priorities::PrioritiesAPI
        end

        on 'projects' do
          run ::API::V3::Projects::ProjectsAPI
        end

        on 'queries' do
          run ::API::V3::Queries::QueriesAPI
        end

        on 'render' do
          run ::API::V3::Render::RenderAPI
        end

        on 'statuses' do
          run ::API::V3::Statuses::StatusesAPI
        end

        on 'users' do
          run ::API::V3::Users::UsersAPI
        end

        on 'work_packages' do
          run ::API::V3::WorkPackages::WorkPackagesAPI
        end

        on root do
          res.write RootRepresenter.new({}).to_json
        end
      end
    end
  end
end
