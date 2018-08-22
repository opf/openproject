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

require 'open3'
require 'fileutils'
require 'rest-client'

module OpenProject::TextFormatting::Formats
  module Markdown
    module PandocDownloader
      class << self
        def check_or_download!
          # Return if we have another version defined in ENV
          if forced_pandoc_path
            return compatible? forced_pandoc_path,
                               "Environment variable OPENPROJECT_PANDOC_PATH set, but version is not executable by OpenProject or incompatible."
          end

          # Return if we have a compatible version
          return if compatible?

          warn <<~INFO
            You have no compatible (>= 2.0) of pandoc in path. We're now trying to download a recent version for your amd64 linux
            from '#{pandoc_amd64_tar}' to '#{vendored_pandoc_dir}'.

            For more information, please visit this page: https://www.openproject.org/textile-to-markdown-migration
          INFO

          download!

          raise "Failed to download pandoc version" unless compatible?
        rescue StandardError => e
          warn <<~WARNING
            Error occurred while trying to find / download compatible pandoc version for your system:

            #{e.message}
          WARNING
        end

        ##
        # Check if the given pandoc version is compatible
        # Returns true/false
        # Raises raise_msg if set and incompatible
        def compatible?(path = pandoc_path, raise_msg = nil)
          stdout, _, status = Open3.capture3(path, '--version')

          if !status.success? && raise_msg.present?
            raise raise_msg
          end

          status.success? && stdout.match(/^pandoc [23]\./i)
        end

        def forced_pandoc_path
          ENV['OPENPROJECT_PANDOC_PATH']
        end

        def pandoc_path
          vendored = Rails.root.join('vendor/pandoc/bin/pandoc').to_s

          # Always return the vendored path if we have installed one
          return vendored if File.executable?(vendored)

          ENV.fetch('OPENPROJECT_PANDOC_PATH', 'pandoc')
        end

        def vendored_pandoc_dir
          Rails.root.join('vendor/pandoc').to_s
        end

        def pandoc_amd64_tar
          ENV.fetch('OPENPROJECT_PANDOC_TAR_DOWNLOAD', 'https://github.com/jgm/pandoc/releases/download/2.2.3.2/pandoc-2.2.3.2-linux.tar.gz')
        end

        private

        def download!
          response = RestClient::Request.execute method: :get,
                                                 url: pandoc_amd64_tar,
                                                 raw_response: true
          tempfile = response.file

          # Create vendor dir, this will however usually exist already
          FileUtils.mkdir_p vendored_pandoc_dir

          begin
            # Extract downloaded tar into vendor
            _, stderr_str, status = Open3.capture3('tar', 'xvzf', tempfile.path.to_s,
                                                   '--strip-components', '1', '-C', vendored_pandoc_dir)
            raise stderr_str unless status.success?
          ensure
            tempfile.unlink
          end
        end
      end
    end
  end
end
