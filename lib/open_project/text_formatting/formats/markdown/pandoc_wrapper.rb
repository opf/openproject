#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'posix-spawn'

module OpenProject::TextFormatting::Formats
  module Markdown
    class PandocWrapper

      attr_reader :logger

      def initialize(logger = ::Logger.new(STDOUT))
        @logger = logger
      end

      def execute!(stdin)
        PandocDownloader.check_or_download!
        run_pandoc! pandoc_arguments, stdin_data: stdin
      end

      def check_arguments!
        PandocDownloader.check_or_download!
        wrap_mode
        read_output_formats
      end

      def pandoc_arguments
        [
          wrap_mode,
          '--atx-headers',
          '-f',
          'textile',
          '-t',
          output_format
        ]
      end

      ##
      # Detect available output markdown format
      # pandoc recommends format 'gfm' but that isnt available in current LTS
      # markdown_github, which is deprecated, is however available.
      def output_format
        if gfm_supported?
          'gfm'
        else
          'markdown_github'
        end
      end

      ##
      # Detect available wrap mode
      # --wrap=preserve will keep the wrapping the same, however is only available in versions 1.16+
      # In older versions we try to use the deprecated --no-wrap instead
      # --atx-headers will lead to headers like `### Some header` and '## Another header'
      def wrap_mode
        @wrap_mode ||= begin
          usage = read_usage_string

          # Detect wrap usage
          if usage.include? '--wrap='
            '--wrap=preserve'
          elsif usage.include? '--no-wrap'
            '--no-wrap'
          else
            err = 'Your pandoc version has neither --no-wrap nor --wrap=preserve. Please install a recent version of pandoc.'
            logger.error err
            raise err
          end
        end
      end

      ##
      # Detect whether an output format for gfm exists
      # so we don't have to use the legacy github_markdown format.
      def gfm_supported?
        read_output_formats.match? /^gfm$/
      end

      def pandoc_timeout
        ENV.fetch('OPENPROJECT_PANDOC_TIMEOUT_SECONDS', 30).to_i
      end

      private

      ##
      # Run pandoc through posix-spawn and raise if an exception occurred
      def run_pandoc!(command, stdin_data: nil, timeout: pandoc_timeout)
        child = POSIX::Spawn::Child.new(PandocDownloader.pandoc_path, *command, input: stdin_data, timeout: timeout)
        raise child.err unless child.status.success?

        # posix-spawn forces binary output, however pandoc
        # only works with UTF-8
        child.out.force_encoding('UTF-8')
      rescue POSIX::Spawn::TimeoutExceeded => e
        raise Timeout::Error, "Timeout occurred while running pandoc: #{e.message}"
      end

      def read_usage_string
        run_pandoc! %w[--help]
      end

      def read_output_formats
        @output_formats ||= begin
          begin
            run_pandoc! %w[--list-output-formats]
          rescue StandardError => e
            logger.warn "Failed to detect output format (Error was: #{e}). Falling back to github_markdown"
            ''
          end
        end
      end
    end
  end
end
