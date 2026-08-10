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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module Wizard
    class ProjectAttributesStepComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(type:)
        super(type)
      end

      def call
        render(WorkPackageTypes::ReloadableConfigurationFrameComponent.new(reload_url:)) do
          render(WorkPackageTypes::ReuseModeBannerComponent.new(
                   type: model,
                   aspect: Type::ConfigurationLink::PROJECT_ATTRIBUTES,
                   routes: helpers.type_routes
                 )) +
            render(WorkPackageTypes::ProjectAttributes::IndexComponent.new(
                     type: model,
                     project_custom_field_sections:
                   ))
        end
      end

      private

      def project_custom_field_sections
        ProjectCustomFieldSection.grouped_in_order(ProjectCustomField.visible)
      end

      def reload_url
        helpers.type_routes.wizard(step: :project_attributes)
      end
    end
  end
end
