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

require "open_project/scm/adapters"
require "pathname"

module OpenProject
  module SCM
    module Adapters
      class Base
        include CheckoutInstructions

        attr_accessor :url, :root_url

        def self.vendor
          name.demodulize.underscore
        end

        def initialize(url, root_url = nil)
          self.url = url
          self.root_url = root_url
        end

        def local?
          false
        end

        ##
        # Overridden by descendants when
        # they are able to retrieve current
        # storage usage.
        def storage_available?
          false
        end

        def available?
          check_availability!
          true
        rescue Exceptions::SCMError => e
          logger.error("Failed to retrieve availability of repository: #{e.message}")
          false
        end

        def logger
          Rails.logger
        end

        def vendor
          self.class.vendor
        end

        def info
          nil
        end

        # Returns the entry identified by path and revision identifier
        # or nil if entry doesn't exist in the repository
        def entry(path = nil, identifier = nil)
          parts = split_path(path)
          search_entries(parts, identifier)
        end

        ##
        # Split path according to the local filesystem
        def split_path(path)
          Pathname(path.to_s)
            .each_filename
            .select { |n| n.present? }
        end

        def search_entries(parts, identifier)
          search_path = parts[0..-2].join("/")
          search_name = parts[-1]

          if search_path.blank? && search_name.blank?
            # Root entry
            Entry.new(path: "", kind: "dir")
          else
            # Search for the entry in the parent directory
            es = entries(search_path, identifier)
            es ? es.detect { |e| e.name == search_name } : nil
          end
        end

        # Returns an Entries collection
        # or nil if the given path doesn't exist in the repository
        def entries(_path = nil, _identifier = nil)
          nil
        end

        def branches
          nil
        end

        def tags
          nil
        end

        def default_branch
          nil
        end

        def properties(_path, _identifier = nil)
          nil
        end

        def revisions(_path = nil, _identifier_from = nil, _identifier_to = nil, _options = {})
          nil
        end

        def diff(_path, _identifier_from, _identifier_to = nil)
          nil
        end

        def cat(_path, _identifier = nil)
          nil
        end

        def with_leading_slash(path)
          path ||= ""
          path[0, 1] == "/" ? path : "/#{path}"
        end

        def with_trailling_slash(path)
          path ||= ""
          path[-1, 1] == "/" ? path : "#{path}/"
        end

        def without_leading_slash(path)
          path ||= ""
          path.gsub(%r{\A/+}, "")
        end

        def without_trailling_slash(path)
          path ||= ""
          path[-1, 1] == "/" ? path[0..-2] : path
        end
      end

      class Info
        attr_accessor :root_url, :lastrev

        def initialize(attributes = {})
          self.root_url = attributes[:root_url] if attributes[:root_url]
          self.lastrev = attributes[:lastrev]
        end
      end
    end
  end
end
