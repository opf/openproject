#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'open3'
module OpenProject
  module Scm
    module Adapters
      module LocalClient
        ##
        # Determines local capabilities for SCM creation.
        # Overridden by including classes when SCM may be remote.
        def local?
          true
        end

        ##
        # Reads the configuration for this strategy from OpenProject's `configuration.yml`.
        def scm_config
          OpenProject::Configuration[:scm]
          %w(scm global_basic_auth).inject(config) do |acc, key|
            HashWithIndifferentAccess.new acc[key]
          end
        end

        ##
        # client executable command
        def client_command
          ''
        end

        def client_available
          !client_version.empty?
        end

        ##
        # Returns the version of the scm client
        # Eg: [1, 5, 0] or [] if unknown
        def client_version
          []
        end

        ##
        # Returns the version string of the scm client
        # Eg: '1.5.0' or 'Unknown version' if unknown
        def client_version_string
          v = client_version || 'Unknown version'
          v.is_a?(Array) ? v.join('.') : v.to_s
        end

        ##
        # Returns true if the current client version is above
        # or equals the given one
        # If option is :unknown is set to true, it will return
        # true if the client version is unknown
        def client_version_above?(v, options = {})
          ((client_version <=> v) >= 0) || (client_version.empty? && options[:unknown])
        end

        def shell_quote(str)
          Shellwords.escape(str)
        end

        def supports_cat?
          true
        end

        def supports_annotate?
          respond_to?('annotate')
        end

        def target(path = '')
          base = path.match(/\A\//) ? root_url : url
          shell_quote("#{base}/#{path}".gsub(/[?<>\*]/, ''))
        end

        # Executes the given arguments for +client_command+ on the shell
        # and returns the resulting stdout.
        #
        # May optionally specify an opts hash with flags for popen3 and Process.spawn
        # (cf., :binmode, :stdin_data in +Open3.capture3+)
        #
        # If the operation throws an exception or the operation yields a non-zero exit code
        # we rethrow a +CommandFailed+ with a meaningful error message
        def capture_out(args, opts = {})
          output, err, code = Open3.capture3(client_command, *args, binmode: opts[:binmode])
          if code != 0
            error_msg = "SCM command failed: Non-zero exit code (#{code}) for `#{client_command}`"
            logger.error(error_msg)
            logger.debug("Error output is #{err}")
            raise CommandFailed.new(client_command, stripped_command(args), error_msg)
          end

          output
        end

        # Executes the given arguments for +client_command+ on the shell
        # and returns stdout, stderr, and the exit code.
        #
        # If the operation throws an exception or the operation we rethrow a
        # +CommandFailed+ with a meaningful error message.
        def popen3(args, opts = {}, &block)
          logger.debug "Shelling out: `#{stripped_command(args)}`"
          Open3.popen3(client_command, *args, opts, &block)
        rescue => e
          error_msg = "SCM command for `#{client_command}` failed: #{strip_credential(e.message)}"
          logger.error(error_msg)
          raise CommandFailed.new(client_command, stripped_command(args), error_msg)
        end

        ##
        # Returns the full client command and args with stripped credentials
        def stripped_command(args)
          "#{client_command} #{strip_credential(args.join(' '))}"
        end

        ##
        # Replaces argument values for --username/--password in a given command
        # with a placeholder
        def strip_credential(cmd)
          q = Redmine::Platform.mswin? ? '"' : "'"
          cmd.to_s.gsub(/(\-\-(password|username))\s+(#{q}[^#{q}]+#{q}|[^#{q}]\S+)/, '\\1 xxxx')
        end

        def scm_encode(to, from, str)
          return nil if str.nil?
          return str if to == from
          begin
            str.to_s.encode(to, from)
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => err
            logger.error("failed to convert from #{from} to #{to}. #{err}")
            nil
          end
        end
      end
    end
  end
end
