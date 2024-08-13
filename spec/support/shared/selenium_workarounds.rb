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

# Ensuring that send_keys fill in the entire string
# This may happen with ChromeDriver versions and send_keys
# https://bugs.chromium.org/p/chromedriver/issues/detail?id=1771
module SeleniumWorkarounds
  def ensure_value_is_input_correctly(input, value:)
    if using_cuprite?
      input.set value
      return
    end

    correctly_set = false
    # Wait longer and longer to set the value, until it is set correctly.
    # The bug may be fixed by now...
    [0, 0.5, 1].each do |waiting_time|
      sleep(waiting_time)
      input.set value
      sleep(waiting_time)

      correctly_set = (input.value == value)
      break if correctly_set
    end

    raise "Found value #{input.value}, but expected #{value}." unless correctly_set
  end
end
