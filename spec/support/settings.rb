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

def week_with_saturday_and_sunday_as_weekend
  Setting.working_days = Array(1..5)
end

def week_with_all_days_working
  Setting.working_days = Array(1..7)
end

def week_with_no_working_days
  # This a hack to make all days non-working,
  # because we don't allow that by definition
  Setting.working_days = [false]
end

def set_non_working_week_days(*days)
  week_days = get_week_days(*days)
  Setting.working_days -= week_days
end

def set_working_week_days(*days)
  week_days = get_week_days(*days)
  Setting.working_days += week_days
end

def set_week_days(*days, working: true)
  if working
    set_working_week_days(*days)
  else
    set_non_working_week_days(*days)
  end
end

def set_work_week(*days)
  week_days = get_week_days(*days)
  Setting.working_days = week_days
end

def get_week_days(*days)
  days.map do |day|
    %w[xxx monday tuesday wednesday thursday friday saturday sunday].index(day.downcase)
  end
end

def default_auto_hide_popups_false
  Setting.default_auto_hide_popups = false
end

RSpec.configure do |config|
  config.before(:suite) do
    # The test suite assumes the default of all days working.
    # Since the Setting default is with Sat-Sun non-working, we update it before the tests.
    week_with_all_days_working
    default_auto_hide_popups_false
  end
end
