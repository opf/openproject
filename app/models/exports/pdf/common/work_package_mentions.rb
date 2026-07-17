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

module Exports::PDF::Common::WorkPackageMentions
  include Redmine::I18n

  def expand_wp_mention(work_package, content)
    detail_level = content.count("#")
    return work_package.formatted_id if detail_level == 1

    # ##: {Type} {formatted_id}: {Subject}
    content = "#{work_package.type} #{work_package.formatted_id}: #{work_package.subject}"
    return content if detail_level == 2

    # ###: {Status} {Type} {formatted_id}: {Subject} ({Start Date} - {End Date})
    "#{work_package.status.name} #{content}#{work_package_dates(work_package)}"
  end

  def work_package_dates(work_package)
    return "" if work_package.start_date.blank? && work_package.due_date.blank?

    if work_package.due_date.present? && work_package.start_date == work_package.due_date
      return " (#{format_date(work_package.due_date)})"
    end

    work_package_date_range(work_package)
  end

  def work_package_date_range(work_package)
    content = [
      work_package.start_date.present? ? format_date(work_package.start_date) : I18n.t("label_no_start_date"),
      work_package.due_date.present? ? format_date(work_package.due_date) : I18n.t("label_no_due_date")
    ].join(" - ")
    " (#{content})"
  end
end
