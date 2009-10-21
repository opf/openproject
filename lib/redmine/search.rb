# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
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
  module Search
    module Controller
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        @@default_search_scopes = Hash.new {|hash, key| hash[key] = {:default => nil, :actions => {}}}
        mattr_accessor :default_search_scopes
        
        # Set the default search scope for a controller or specific actions
        # Examples:
        #   * search_scope :issues # => sets the search scope to :issues for the whole controller
        #   * search_scope :issues, :only => :index
        #   * search_scope :issues, :only => [:index, :show]
        def default_search_scope(id, options = {})
          if actions = options[:only]
            actions = [] << actions unless actions.is_a?(Array)
            actions.each {|a| default_search_scopes[controller_name.to_sym][:actions][a.to_sym] = id.to_s}
          else
            default_search_scopes[controller_name.to_sym][:default] = id.to_s
          end
        end
      end

      def default_search_scopes
        self.class.default_search_scopes
      end

      # Returns the default search scope according to the current action
      def default_search_scope
        @default_search_scope ||= default_search_scopes[controller_name.to_sym][:actions][action_name.to_sym] ||
                                  default_search_scopes[controller_name.to_sym][:default]
      end
    end
  end
end
