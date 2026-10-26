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

module SquashTMIntegration
  module WorkPackageTab
    class RequirementLinkForm < ApplicationForm
      form do |f|
        f.select_list(
          name: :squashtm_requirement_id,
          label: attribute_name(:squashtm_requirement_id),
          include_blank: I18n.t("squashtm_integration.work_package_tab.requirement_link_form.prompt"),
          required: true,
          input_width: :large
        ) do |list|
          @requirement_options.each do |requirement|
            list.option(
              value: requirement[:id],
              label: requirement[:name],
              selected: requirement[:id] == model.squashtm_requirement_id
            )
          end
        end

        f.submit(
          name: :submit,
          label: I18n.t("squashtm_integration.work_package_tab.requirement_link_form.submit"),
          scheme: :primary
        )
      end

      def initialize(requirement_options:)
        super()
        @requirement_options = requirement_options
      end
    end
  end
end
