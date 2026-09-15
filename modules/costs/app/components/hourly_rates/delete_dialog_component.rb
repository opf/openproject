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
  class DeleteDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    DIALOG_ID = "hourly-rate-delete-dialog"

    options :rate

    private

    def form_arguments
      { action: destroy_url, method: :delete }
    end

    def destroy_url
      if rate.is_a?(DefaultHourlyRate)
        default_hourly_rate_path(rate)
      else
        hourly_rate_path(rate)
      end
    end

    def description
      I18n.t(:text_hourly_rate_destroy_confirmation,
             valid_from: helpers.format_date(rate.valid_from),
             rate: helpers.number_to_currency(rate.rate))
    end
  end
end
