# frozen_string_literal: true

# -- copyright
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
# ++

module WorkPackages
  module Create
    class WpCreateButtonComponent < ApplicationComponent
      include ApplicationHelper

      def initialize(project: nil)
        super
        @project = project
      end

      def items
        if @project
          @project.types.all
        else
          Type.all
        end
      end

      def create_href_for_type(type)
        # TODO: make configurable for other modules
        if @project
          split_create_project_work_packages_path(@project, type: type.id)
        else
          split_create_work_packages_path(type: type.id)
        end
      end

      def can_create_work_packages?
        if @project
          helpers.current_user.allowed_in_project?(:add_work_packages, @project)
        else
          helpers.current_user.allowed_in_any_project?(:add_work_packages)
        end
      end
    end
  end
end
