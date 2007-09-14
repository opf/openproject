# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module Redmine
  module MenuManager
    
    class << self
      def map(menu_name)
        mapper = Mapper.new
        yield mapper
        @items ||= {}
        @items[menu_name.to_sym] ||= []
        @items[menu_name.to_sym] += mapper.items
      end
      
      def items(menu_name)
        @items[menu_name.to_sym] || []
      end
      
      def allowed_items(menu_name, user, project)
        items(menu_name).select {|item| user && user.allowed_to?(item.url, project)}
      end
    end
    
    class Mapper
      def push(name, url, options={})
        @items ||= []
        @items << MenuItem.new(name, url, options)
      end
      
      def items
        @items
      end
    end
    
    class MenuItem
      attr_reader :name, :url, :param, :condition
      
      def initialize(name, url, options)
        @name = name
        @url = url
        @condition = options[:if]
        @param = options[:param] || :id
      end
    end    
  end
end
