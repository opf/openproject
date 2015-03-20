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

##
# Hack against rabl 0.9.3 which applies config.include_child_root to
# #collection as well as to #child calls as you would expect.
#
module Rabl
  class Engine
    def to_hash_with_hack(options = {})
      if is_collection?(@_data_object)
        options[:building_collection] = true
      end
      to_hash_without_hack(options)
    end

    alias_method :to_hash_without_hack, :to_hash
    alias_method :to_hash, :to_hash_with_hack
  end

  class Builder
    def compile_hash_with_hack(options = {})
      if options[:building_collection] && !options[:child_root]
        options[:root_name] = false
      end
      compile_hash_without_hack(options)
    end

    alias_method :compile_hash_without_hack, :compile_hash
    alias_method :compile_hash, :compile_hash_with_hack
  end
end
