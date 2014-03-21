#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

# Be sure to restart your server when you modify this file.

module Sprockets
  class Base
    def each_entry(root, &block)
      return to_enum(__method__, root) unless block_given?
      root = Pathname.new(root) unless root.is_a?(Pathname)

      paths = []
      entries(root).sort.each do |filename|
        path = root.join(filename)

        # work-around a Sprockets issue with files with no extension
        # https://github.com/sstephenson/sprockets/issues/347
        next if path.extname.empty?
        paths << path

        if stat(path).directory?
          each_entry(path) do |subpath|
            paths << subpath
          end
        end
      end

      paths.sort_by(&:to_s).each(&block)

      nil
    end
  end
end
