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

class Grids::Widgets::TimeEntriesCurrentUserController < Grids::WidgetController
  skip_before_action :load_and_authorize_in_optional_project

  def show
    remember_mode

    render_widget Grids::Widgets::TimeEntriesCurrentUser.new(mode:, date:, current_user:)
  end

  private

  def mode
    requested = (params[:mode].presence || User.current.pref.my_work_mode).to_s.to_sym

    %i[day workweek week].include?(requested) ? requested : :workweek
  end

  def remember_mode
    return if params[:mode].blank?

    preference = User.current.pref
    return if preference.my_work_mode == mode.to_s

    preference.update(my_work_mode: mode.to_s)
  end

  def date
    Date.iso8601(params[:date].to_s)
  rescue StandardError
    Time.zone.today
  end
end
