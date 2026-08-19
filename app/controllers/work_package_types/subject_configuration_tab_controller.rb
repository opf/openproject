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
  class SubjectConfigurationTabController < BaseTabController
    current_menu_item [:edit, :update] do
      :types
    end

    def edit; end

    def update
      permitted = params.expect(work_package_types_forms_subject_configuration_form_model: %i[subject_configuration pattern]).to_h

      result = UpdateService.new(model: @type, user: current_user, contract_class: UpdateSubjectPatternContract)
                            .call(patterns: build_patterns(permitted))

      if result.success?
        redirect_to edit_type_subject_configuration_path(@type), notice: I18n.t(:notice_successful_update)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def build_patterns(form_params)
      case form_params
      in { subject_configuration: "generated", pattern: String => blueprint }
        { subject: { blueprint:, enabled: true } }
      in { subject_configuration: "manual", pattern: String => blueprint }
        if blueprint.empty?
          # Submitting the form with an empty blueprint and manual subject configuration will
          # remove the subject pattern from the collection
          nil
        else
          { subject: { blueprint:, enabled: false } }
        end
      else
        nil
      end
    end
  end
end
