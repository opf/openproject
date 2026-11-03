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

require "json"
require "fileutils"
require "spec_helper"

module RSpecSleepDiagnostics
  ROOT = "#{File.expand_path('../..', __dir__)}/".freeze
  LOG_DIRECTORY = ENV.fetch("RSPEC_SLEEP_DIAGNOSTICS_DIR", "#{ROOT}tmp/rspec-sleep-diagnostics").freeze
  CONDITION_WAITS = {
    "spec/support/retryable.rb" => "bounded assertion polling",
    "spec/support/capybara/wait_helpers.rb" => "animation stability sampling"
  }.freeze

  FileUtils.mkdir_p(LOG_DIRECTORY)

  def self.record(location, path, preserved, seconds)
    record = {
      path:, line: location.lineno, seconds:,
      example: RSpec.current_example&.id, preserved:
    }
    File.open("#{LOG_DIRECTORY}/#{ENV.fetch('TEST_ENV_NUMBER', '0')}.jsonl", "a") do |file|
      file.write("#{JSON.generate(record)}\n")
    end
  end

  def sleep(*arguments)
    location = caller_locations(1, 1).first
    path = File.expand_path(location.absolute_path || location.path).delete_prefix(ROOT)
    return super unless path.start_with?("spec/") || path.match?(%r{\Amodules/[^/]+/spec/})

    preserved = CONDITION_WAITS[path]
    RSpecSleepDiagnostics.record(location, path, preserved, arguments.first)
    return super if preserved

    Thread.pass
    0
  end
end

Kernel.prepend(RSpecSleepDiagnostics)
Kernel.singleton_class.prepend(RSpecSleepDiagnostics)

RSpec.configure do |config|
  config.before(:suite) do
    raise "Sleep diagnostic requires RSPEC_RETRY_RETRY_COUNT=0" unless ENV["RSPEC_RETRY_RETRY_COUNT"] == "0"

    config.reporter.message("DIAGNOSTIC RUN: fixed test sleeps and RSpec retries disabled; condition waits retained")
  end
end
