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
  class CurrentRateComponent < ApplicationComponent
    include OpTurbo::Streamable

    options rate: nil,
            fallback_rate: nil,
            project: nil

    # Rendered once per rate table, and replaced alongside it whenever a rate
    # is written, so it needs the same per scope addressing.
    def wrapper_uniq_by
      project&.id || "default"
    end

    private

    # Without a rate of its own a project bills at the default rate, so the
    # label names which of the two is in effect.
    def caption
      if rate
        labelled(I18n.t(:label_current), rate)
      elsif fallback_rate
        labelled(I18n.t(:label_using_current_default_rate), fallback_rate)
      end
    end

    def labelled(label, applicable_rate)
      "#{label}: #{helpers.number_to_currency(applicable_rate.rate)}"
    end
  end
end
