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

module WorkPackageTypes
  module Wizard
    # Embeds the projects tab's listing, whose dialogs and actions persist through the tab's own
    # turbo endpoints; the wizard only navigates between steps.
    class ProjectsStepComponent < ApplicationComponent
      def initialize(variant:, reload_url:)
        super(variant)

        @reload_url = reload_url
      end

      def call
        render(ReloadableConfigurationFrameComponent.new(reload_url: @reload_url, reload_from_location: true)) do
          safe_join([
                      render(AspectDescriptionComponent.new(variant: model, aspect: :projects)),
                      render(helpers.sub_header_component),
                      render(helpers.projects_table_component)
                    ])
        end
      end
    end
  end
end
