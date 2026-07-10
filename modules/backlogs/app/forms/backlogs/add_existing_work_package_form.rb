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

module Backlogs
  class AddExistingWorkPackageForm < ApplicationForm
    def initialize(project:, target_id: nil)
      super()

      @project = project
      @target_id = target_id
    end

    form do |f|
      f.work_package_autocompleter(
        name: :work_package_id,
        label: WorkPackage.model_name.human,
        required: true,
        autocomplete_options: {
          url: autocomplete_url,
          dropdownPosition: "bottom",
          appendTo: "##{AddExistingWorkPackageDialogComponent::DIALOG_ID}",
          filters:
        }
      )
    end

    private

    def autocomplete_url
      ::API::V3::Utilities::PathHelper::ApiV3Path.work_packages_by_project(@project.id)
    end

    def filters
      [
        { name: "status", operator: Queries::Operators::OpenWorkPackages.symbol },
        Target.parse(@target_id).to_filter
      ]
    end
  end
end
