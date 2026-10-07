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

class My::DateTimeFormatForm < ApplicationForm
  include Redmine::I18n

  # TODO Gregor:
  #   - [ ] Add sub heading
  #   - [ ] Make "fallback" label more specific
  form do |f|
    f.select_list(
      name: :date_format,
      label: I18n.t(:setting_date_format),
      include_blank: I18n.t(:label_language_based),
      input_width: :medium
    ) do |list|
      Settings::Definition[:date_format].allowed.each do |format|
        list.option(label: Time.zone.today.strftime(format), value: format)
      end
    end

    f.select_list(
      label: I18n.t(:setting_time_format),
      name: :time_format,
      input_width: :medium,
      include_blank: I18n.t(:label_language_based)
    ) do |list|
      Settings::Definition[:time_format].allowed.each do |format|
        list.option(label: Time.current.strftime(format), value: format)
      end
    end
  end
end
