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

module Api
  module Experimental
    class UsersController < ApplicationController
      include ::Api::Experimental::ApiController

      before_filter :find_optional_project

      def index
        @users = if @project
                   projects_principals
                 else
                   visible_users
                 end

        respond_to do |format|
          format.api
        end
      end

      private

      def visible_users
        visible_project_ids = Project.visible.all.map(&:id)
        desired_classes = if Setting.work_package_group_assignment?
                            ['User', 'Group']
                          else
                            ['User']
                          end

        Principal.active.where(["#{User.table_name}.type IN (?) AND " \
                                "#{User.table_name}.id IN " \
                                  '(SELECT DISTINCT user_id FROM members WHERE project_id IN (?))',
                                desired_classes,
                                visible_project_ids]).sort
      end

      def projects_principals
        principals = if Setting.work_package_group_assignment?
                       @project.principals
                     else
                       @project.users
                     end

        principals.sort
      end
    end
  end
end
