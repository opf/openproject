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

class WorkPackageTypes::FormConfiguration::QuerySummaryTimestamp
  def initialize(timestamp)
    @timestamp = timestamp
  end

  def text
    return I18n.t("js.label_current").upcase_first if @timestamp == Timestamp.now
    return unavailable_value unless @timestamp.valid?
    return duration_text if @timestamp.duration?
    return keyword_text if @timestamp.relative_date_keyword?

    Redmine::I18n.format_time(@timestamp.to_time)
  rescue ArgumentError, Timestamp::Exception
    unavailable_value
  end

  private

  def unavailable_value
    I18n.t("queries.filter_summary.unavailable_value")
  end

  def duration_text
    parts = @timestamp.to_duration.parts.filter_map do |unit, amount|
      I18n.t("datetime.distance_in_words.x_#{unit}", count: amount.abs) unless amount.zero?
    end
    I18n.t("time.relative_ago", time: parts.to_sentence)
  end

  def keyword_text
    key = {
      "oneDayAgo" => "yesterday",
      "lastWorkingDay" => "last_working_day",
      "oneWeekAgo" => "last_week",
      "oneMonthAgo" => "last_month"
    }.fetch(@timestamp.to_s.split("@").first)
    I18n.t(
      "time.relative_at",
      relative: I18n.t("js.baseline.drop_down.#{key}").upcase_first,
      time: Redmine::I18n.format_time(@timestamp.to_time)
    )
  end
end
