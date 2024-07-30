# frozen_string_literal: true

# -- copyright
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
# ++
#

# Sets up aliases to examples/example groups in order to automatically
# pry into the state of the spec when an expectation fails or the example exits
# due to an exception and debug why it's happening without having to have to maneuver
# your way through the codebase and add a pry statement in a very specific location.
#
# This is akin to using `fit` to set `focus: true` on an example.
RSpec.configure do |config|
  config.alias_example_to :pit, pry: true
  config.alias_example_to :pspecify, pry: true
  config.alias_example_to :pexample, pry: true
  config.alias_example_group_to :pdescribe, pry: true
  config.alias_example_group_to :pcontext, pry: true

  config.after(pry: true) do |example|
    if example.exception
      exception_message = example.exception.message
      backtrace_locations = example.exception.backtrace_locations.filter { _1.to_s.include? "/spec/" }

      puts
      puts exception_message
      puts backtrace_locations
      puts

      # rubocop:disable Lint/Debugger
      require "pry"
      binding.pry
      # rubocop:enable Lint/Debugger
    end
  end
end
