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

module SkipIfCommandUnavailableMixin
  # Ensure given command(s) exist by running it with `--help`.
  # If the command does not exist, the test is skipped.
  #
  # The test is not skipped if in continuous integration environment.
  def skip_if_commands_unavailable(*commands)
    return if ENV["CI"]

    commands.flatten.compact.each do |cmd|
      # Avoid `which`, as it's not POSIX
      Open3.capture2e(cmd, "--version")
    rescue Errno::ENOENT
      skip "Skipped because '#{cmd}' command not found in PATH"
    end
  end

  alias :skip_if_command_unavailable :skip_if_commands_unavailable
end

RSpec.configure do |config|
  include SkipIfCommandUnavailableMixin

  config.before :all, :skip_if_command_unavailable do
    skip_if_command_unavailable(self.class.metadata[:skip_if_command_unavailable])
  end

  config.before :all, :skip_if_commands_unavailable do
    skip_if_command_unavailable(self.class.metadata[:skip_if_commands_unavailable])
  end

  config.before :example, :skip_if_command_unavailable do |example|
    skip_if_command_unavailable(example.metadata[:skip_if_command_unavailable])
  end

  config.before :example, :skip_if_commands_unavailable do |example|
    skip_if_command_unavailable(example.metadata[:skip_if_commands_unavailable])
  end
end
