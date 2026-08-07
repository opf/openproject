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

module Projects::Settings::WorkPackages::Types::Variants
  class CreationWizardController < ::WorkPackageTypes::CreationWizardController
    include ProjectScoped

    # The wizard fills the screen in administration too, and nothing about being inside a
    # project changes that.
    layout "no_menu"

    def new
      @type = ::Type.new(parent_id: params[:parent_id], project: @project)
      @current_step = ::WorkPackageTypes::Wizard::Steps.first

      render :show
    end

    private

    # The owner is never read off the request: a project administrator running this wizard
    # is creating a variant here and nowhere else.
    def details_params
      super.to_h.symbolize_keys.merge(project: @project)
    end

    def redirect_to_step(step)
      if step
        redirect_to project_settings_work_packages_types_variant_creation_wizard_path(@project, @type, step:),
                    status: :see_other
      else
        redirect_to project_settings_work_packages_types_path(@project),
                    notice: t("types.creation_wizard.success"),
                    status: :see_other
      end
    end
  end
end
