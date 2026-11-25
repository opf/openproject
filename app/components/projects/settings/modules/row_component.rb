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
      class RowComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers

        def initialize(project:, name:, required_by:)
          super

          @project = project
          @name = name.to_s
          @required_by = required_by
        end

        private

        def module_label
          I18n.t("project_module_#{@name}", default: @name.humanize)
        end

        def toggle_path
          toggle_project_settings_modules_path(@project, name: @name)
        end

        def toggle_checked? = @project.module_enabled?(@name)

        def locked_reason
          return if @required_by.empty?

          I18n.t("projects.settings.modules.required_by",
                 count: @required_by.size,
                 modules: @required_by.map { I18n.t("project_module_#{it}", default: it.humanize) }.to_sentence)
        end

        def enterprise_upsell?
          feature = OpenProject::AccessControl.module_enterprise_feature?(@name)

          feature.present? && !EnterpriseToken.allows_to?(feature)
        end
      end
    end
  end
end
