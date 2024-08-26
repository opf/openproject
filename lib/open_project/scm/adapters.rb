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
module OpenProject
  module SCM
    module Adapters
      class Entries < Array
        def sort_by_name
          sorted = sort do |x, y|
            if x.kind == y.kind
              x.name.to_s <=> y.name.to_s
            else
              x.kind <=> y.kind
            end
          end

          entries = Entries.new sorted
          entries.truncated = truncated

          entries
        end

        def truncated=(truncated)
          @truncated = truncated
        end

        def truncated
          @truncated
        end

        def truncated?
          @truncated
        end
      end

      class Info
        attr_accessor :root_url, :lastrev

        def initialize(attributes = {})
          self.root_url = attributes[:root_url]
          self.lastrev = attributes[:lastrev]
        end
      end

      class Entry
        attr_accessor :name, :path, :kind, :size, :lastrev

        def initialize(attributes = {})
          %i[name path kind size].each do |attr|
            send(:"#{attr}=", attributes[attr])
          end

          self.size = size.to_i if size.present?
          self.lastrev = attributes[:lastrev]
        end

        def file?
          "file" == kind
        end

        def dir?
          "dir" == kind
        end
      end

      class Revisions < Array
        def latest
          max do |x, y|
            if x.time.nil? or y.time.nil?
              0
            else
              x.time <=> y.time
            end
          end
        end
      end

      class Revision
        attr_accessor :scmid, :name, :author, :time, :message, :paths, :revision, :branch
        attr_writer :identifier

        def initialize(attributes = {})
          %i[identifier scmid author time paths revision branch].each do |attr|
            send(:"#{attr}=", attributes[attr])
          end

          self.name = attributes[:name].presence || identifier
          self.message = attributes[:message].presence || ""
        end

        # Returns the identifier of this revision; see also Changeset model
        def identifier
          (@identifier || revision).to_s
        end

        # Returns the readable identifier.
        def format_identifier
          identifier
        end
      end

      class Annotate
        attr_reader :lines, :revisions

        def initialize
          @lines = []
          @revisions = []
        end

        def add_line(line, revision)
          @lines << line
          @revisions << revision
        end

        def content
          lines.join("\n")
        end

        delegate :empty?, to: :lines
      end
    end
  end
end
