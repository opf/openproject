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

class Users::WorkingHours::AvailabilityFactorForm < ApplicationForm
  form do |form|
    form.html_content do
      render(Primer::Beta::Subhead.new(spacious: true)) do |component|
        component.with_heading(tag: :div) do
          I18n.t("users.working_hours.form.title_availability_factor")
        end

        component.with_description do
          I18n.t("users.working_hours.form.availability_description")
        end
      end
    end

    form.text_field name: :availability_factor,
                    label: UserWorkingHours.human_attribute_name(:availability_factor),
                    caption: I18n.t("users.working_hours.form.availability_factor_caption"),
                    input_width: :large,
                    inputmode: "numeric",
                    value: model.availability_factor,
                    data: {
                      "users--working-hours-form-target": "availabilityFactorInput",
                      action: "input->users--working-hours-form#availabilityChanged"
                    },
                    trailing_visual: { text: { text: "%" } }

    form.text_field name: :total_factored_hours,
                    label: I18n.t("users.working_hours.form.total_available_hours"),
                    input_width: :large,
                    readonly: true,
                    data: { "users--working-hours-form-target": "totalAvailableHoursDisplay" },
                    trailing_visual: { text: { text: I18n.t("users.working_hours.form.per_week") } }
  end
end
