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

class WorkPackages::HighlightedDateComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, text_arguments: {})
    super

    @work_package = work_package
    @start_date = work_package.start_date
    @due_date = work_package.due_date

    @text_arguments = text_arguments
  end

  def parsed_date(date)
    return if date.nil?

    date.strftime(I18n.t("date.formats.default"))
  end

  def date_classes(date)
    return if date.nil?

    diff = (date - Time.zone.today).to_i
    if diff === 0
      return "__hl_date_due_today"
    elsif diff <= -1
      return "__hl_date_overdue"
    end

    "__hl_date_not_overdue"
  end
end
