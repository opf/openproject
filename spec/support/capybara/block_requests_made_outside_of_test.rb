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

# When test is finished, Capybara calls `Capybara.reset!` which in turn calls
# `driver.reset!`. This one is responsible for stopping the browser by
# navigating to about:blank page and waiting for pending requests to complete.
#
# With Cuprite, we observed that some requests could still be triggered from the
# browser after `Capybara.reset!` is called. It can interfere with test
# execution is some unexpected ways: when a request to the API is made, the
# settings are read from the database. If this happens right when the database
# is being rolled back to a previous savepoint (which happens when using
# `before_all` helper), then in postgres dapater code there is a `nil` reference
# instead of a result, and then it errs with "NoMethodError: undefined method
# 'clear' for nil".
#
# You can run tests from `spec/features/work_packages/progress_modal_spec.rb` a
# couple of times to experiment the error. It happens mostly with tests having
# the most nested `before_all` calls.
#
# We tried navigating to about:blank with Cuprite, but some requests were still
# made. So we looked for another fix.
#
# Using a middleware to actively block requests outside of test execution fixed
# the issue.

class RequestsBlocker
  def initialize(app)
    @app = app
    @blocked = false
    @active_requests = 0
    @mutex = Mutex.new
    @requests_finished = ConditionVariable.new
  end

  def block_requests!(timeout: 30)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    @mutex.synchronize do
      @blocked = true

      while @active_requests.positive?
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise "Timed out waiting for #{@active_requests} browser request(s) to finish" unless remaining.positive?

        @requests_finished.wait(@mutex, remaining)
      end
    end
  end

  def unblock_requests!
    @mutex.synchronize { @blocked = false }
  end

  def active_requests
    @mutex.synchronize { @active_requests }
  end

  def call(env)
    allowed = @mutex.synchronize do
      unless @blocked
        @active_requests += 1
        true
      end
    end

    return [500, {}, "RequestsBlocker is blocking further requests because test is finished."] unless allowed

    @app.call(env)
  ensure
    if allowed
      @mutex.synchronize do
        @active_requests -= 1
        @requests_finished.broadcast if @active_requests.zero?
      end
    end
  end
end

RSpec.configure do |config|
  Capybara.app = RequestsBlocker.new(Capybara.app)

  config.before do
    Capybara.app.unblock_requests!
  end

  config.after(:each, type: :feature) do
    Capybara.app.block_requests!
  end
end
