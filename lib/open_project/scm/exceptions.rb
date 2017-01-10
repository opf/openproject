#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++
module OpenProject
  module Scm
    module Exceptions
      # Parent SCM exception class
      class ScmError < StandardError
      end

      # Exception marking an error in the repository build process
      class RepositoryBuildError < ScmError
      end

      # Exception marking an error in the repository teardown process
      class RepositoryUnlinkError < ScmError
      end

      # Exception marking an error in the execution of a local command.
      class CommandFailed < ScmError
        attr_reader :program
        attr_reader :message
        attr_reader :stderr

        # Create a +CommandFailed+ exception for the executed program (e.g., 'svn'),
        # and a meaningful error message
        #
        # If the operation throws an exception or the operation we rethrow a
        # +ShellError+ with a meaningful error message.
        def initialize(program, message, stderr = nil)
          @program = program
          @message = message
          @stderr  = stderr
        end

        def to_s
          s = "CommandFailed(#{@program}) -> #{@message}"
          s << "(#{@stderr})" unless @stderr.nil?

          s
        end
      end

      # a localized exception raised when SCM could be accessed
      class ScmUnavailable < ScmError
        def initialize(key = 'unavailable')
          @error = I18n.t("repositories.errors.#{key}")
        end

        def to_s
          @error
        end
      end

      # raised if SCM could not be accessed due to authorization failure
      class ScmUnauthorized < ScmUnavailable
        def initialize
          super('unauthorized')
        end
      end
      # raised when encountering an empty (bare) repository
      class ScmEmpty < ScmUnavailable
        def initialize
          super('empty_repository')
        end
      end
    end
  end
end
