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
  module BurndownChartHelper
    def xaxis_labels(burndown)
      # 14 entries (plus the axis label) have come along as the best value for a good optical result.
      # Thus it is enough space between the entries.
      entries_displayed = (burndown.days.length / 14.0).ceil
      burndown.days.enum_for(:each_with_index).map do |d, i|
        if (i % entries_displayed) == 0
          ["#{::I18n.t('date.abbr_day_names')[d.wday % 7]} #{d.strftime('%d/%m')}"]
        end
      end
    end

    def dataseries(burndown)
      burndown.series.map do |s|
        {
          label: I18n.t("burndown.#{s.first}"),
          data: s.last.enum_for(:each)
        }
      end
    end
  end
end
