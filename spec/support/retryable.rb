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

class Retryable
  WAIT_PERIOD = 0.05
  RETRY_ERRORS = %w[
    RSpec::Expectations::ExpectationNotMetError
    Capybara::ElementNotFound
  ].freeze

  def self.repeat_until_success(max_seconds: RSpec.configuration.wait_timeout, &block)
    repeat_started = system_time
    tries = 0
    begin
      tries += 1
      try_started = system_time
      yield block
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise e unless retryable_error?(e)
      raise e if (try_started - repeat_started) > max_seconds && (tries >= 2)

      sleep(WAIT_PERIOD)
      if system_time == repeat_started
        raise "Time appears to be frozen, can't use Retryable!"
      end

      retry
    end
  end

  # Use the system clock (i.e. seconds since boot) to calculate the time,
  # because Time.now may be frozen
  def self.system_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def self.retryable_error?(error)
    RETRY_ERRORS.include?(error.class.name)
  end
end
