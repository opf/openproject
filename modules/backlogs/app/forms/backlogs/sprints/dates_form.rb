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
  module Sprints
    class DatesForm < ApplicationForm
      extend Dry::Initializer

      option :disabled, default: -> { false }

      delegate :active?, to: :model

      form do |f|
        f.group(layout: :horizontal) do |dates|
          dates.text_field(
            name: :start_date,
            type: :date,
            label: attribute_name(:start_date),
            placeholder: attribute_name(:start_date),
            required: active?,
            disabled:,
            input_width: :small,
            data: {
              action: "change->refresh-on-form-changes#triggerTurboStream"
            }
          )
          dates.text_field(
            name: :finish_date,
            type: :date,
            label: attribute_name(:finish_date),
            placeholder: attribute_name(:finish_date),
            required: active?,
            disabled:,
            input_width: :small,
            data: {
              action: "change->refresh-on-form-changes#triggerTurboStream"
            }
          )
          dates.text_field(
            name: :duration,
            label: attribute_name(:duration),
            input_width: :xsmall,
            readonly: true,
            value: display_duration
          )
        end
      end

      def display_duration
        if model.duration.present?
          [model.duration, I18n.t("datetime.units.day", count: model.duration)].join(" ")
        else
          ""
        end
      end
    end
  end
end
