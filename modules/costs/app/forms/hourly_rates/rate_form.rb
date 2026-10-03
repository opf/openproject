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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module HourlyRates
  class RateForm < ApplicationForm
    form do |f|
      f.hidden(name: :user_id)

      f.single_date_picker(
        name: :valid_from,
        type: "date",
        label: Rate.human_attribute_name(:valid_from),
        required: true,
        input_width: :small,
        leading_visual: { icon: :calendar },
        datepicker_options: { inDialog: HourlyRates::RateDialogComponent::DIALOG_ID }
      )

      f.text_field(
        name: :rate,
        label: Rate.model_name.human,
        required: true,
        input_width: :small,
        autocomplete: "off",
        trailing_visual: { text: { text: Setting.costs_currency } }
      )
    end
  end
end
