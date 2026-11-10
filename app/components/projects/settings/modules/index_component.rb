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

module Projects
  module Settings
    module Modules
      class IndexComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(project:)
          super

          @project = project
        end

        private

        def module_names
          OpenProject::AccessControl.available_project_modules(sorted: true).map(&:to_s)
        end

        # Maps each module onto the enabled modules that force it to stay enabled, by walking
        # every enabled module's dependency closure once.
        def required_by
          @required_by ||= enabled_module_names.each_with_object(Hash.new { |map, key| map[key] = [] }) do |name, map|
            dependencies = OpenProject::AccessControl.modules_with_dependencies_appended([name]) - [name]

            dependencies.each { map[it] << name }
          end
        end

        def enabled_module_names
          @enabled_module_names ||= @project.enabled_module_names
        end
      end
    end
  end
end
