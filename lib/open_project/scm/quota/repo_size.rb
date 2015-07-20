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

require 'find'
require 'yaml'
module OpenProject
  module Scm
    module Quota
      module RepoSize

        ##
        # Determines whether this repository is eligible
        # to count storage.
        def has_storage?
          local? && File.directory?(local_repository_path)
        end

        ##
        # Retrieve the local FS path
        # of this repository.
        #
        # Overriden by some vendors, as not
        # all vendors have a path root_url.
        # (e.g., subversion uses file:// URLs)
        def local_repository_path
          root_url
        end

        ##
        # Read the latest storage estimate
        # from the +reposize+ file.
        # @return [Array] three values stored in the reposize file
        # 1. updated_at: The data this file was last updated
        # 2. bytes_used: Total consumption in MB
        # 3. last mtime: Last detected change in the repository
        # 4. Optional: Additional data from an adapter
        #
        # If the information is older than one day or the
        # information does not exist yet, it is fetched asynchronously.
        def updated_storage_information(repo)
          info = get_reposize_hash
          if info.nil? || info[:updated_at] < 1.day.ago

            # TODO: this may result in a lot of delayed jobs when
            # a number of requests hit for a single project
            # Perhaps restrict active jobs for this repository id?
            Delayed::Job.enqueue ::Scm::StorageUpdaterJob.new(repo)
          end

          info
        end

        ##
        # returns the path to the +reposize+
        def reposize_path
          File.join(local_repository_path, '.reposize')
        end

        ##
        # Builds the +reposize+ content as a hash.
        # For sake of compatibility, iterates all files
        # in the repository to determine mtime and storage size.
        #
        # This is probably quite inefficient.
        def build_repo_data
          storage = 0
          mtime = nil

          Find.find(local_repository_path) do |f|
            storage += File.size(f) if File.file?(f)

            time = File.mtime(f)
            if mtime.nil? || time > mtime
              mtime = time
            end
          end

          repo_data(storage, mtime)
        end

        protected

        def repo_data(storage, mtime)
          {
            updated_at: Time.now,
            bytes_used: storage,
            mtime: mtime,
          }
        end

        private

        ##
        # Read the +.reposize+ YAML information.
        def get_reposize_hash
          if File.exists? reposize_path
            read_reposize_file
          end
        end

        ##
        # Open the reposize file and read the last modification date
        # Along with storage total.
        #
        def read_reposize_file
          YAML.load(File.read(reposize_path))
        end
      end
    end
  end
end
