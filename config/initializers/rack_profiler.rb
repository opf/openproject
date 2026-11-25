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

if Rails.env.local? && ENV["OPENPROJECT_RACK_PROFILER_ENABLED"]
  require "rack-mini-profiler"
  require "flamegraph"
  require "stackprof"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.position = "bottom-right"

  # NOTE: Rack Mini Profiler is generally safe to use in production, e.g.
  #       by only allowing special users to access it.
  #       HOWEVER, memory and GC profiler should NEVER be enabled in production,
  #       as they can expose memory containing secrets.
  if Rails.env.local?
    require "memory_profiler"

    Rack::MiniProfiler.config.enable_advanced_debugging_tools = true
  end
end
