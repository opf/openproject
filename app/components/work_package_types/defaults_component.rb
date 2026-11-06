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
  class DefaultsComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable
    include WorkPackageTypes::VariantRoutes

    def initialize(model, subject_configuration_form_data: nil, readonly: false, **)
      @subject_configuration_form_data = subject_configuration_form_data
      @readonly = readonly
      super(model, **)
    end

    def readonly? = @readonly

    def variant = model

    def form_options
      {
        url: variant_defaults_path(helpers.variant_scope_project, variant),
        method: :put,
        model: subject_form_object,
        readonly: @readonly,
        data: form_data
      }
    end

    private

    def form_data
      return {} if @readonly

      subject_form_object.stimulus_data
    end

    def subject_form_object
      Forms::DefaultsFormModel.build(variant, form_data: @subject_configuration_form_data)
    end
  end
end
