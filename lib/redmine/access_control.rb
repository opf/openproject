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
  module AccessControl
    
    class << self
      def map
        mapper = Mapper.new
        yield mapper
        @permissions ||= []
        @permissions += mapper.mapped_permissions
      end
      
      def permissions
        @permissions
      end
      
      def allowed_actions(permission_name)
        perm = @permissions.detect {|p| p.name == permission_name}
        perm ? perm.actions : []
      end
      
      def public_permissions
        @public_permissions ||= @permissions.select {|p| p.public?}
      end
      
      def members_only_permissions
        @members_only_permissions ||= @permissions.select {|p| p.require_member?}
      end
      
      def loggedin_only_permissions
        @loggedin_only_permissions ||= @permissions.select {|p| p.require_loggedin?}
      end
    end
    
    class Mapper
      def permission(name, hash, options={})
        @permissions ||= []
        @permissions << Permission.new(name, hash, options)
      end
      
      def mapped_permissions
        @permissions
      end
    end
    
    class Permission
      attr_reader :name, :actions
      
      def initialize(name, hash, options)
        @name = name
        @actions = []
        @public = options[:public] || false
        @require = options[:require]
        hash.each do |controller, actions|
          if actions.is_a? Array
            @actions << actions.collect {|action| "#{controller}/#{action}"}
          else
            @actions << "#{controller}/#{actions}"
          end
        end
      end
      
      def public?
        @public
      end
      
      def require_member?
        @require && @require == :member
      end
      
      def require_loggedin?
        @require && (@require == :member || @require == :loggedin)
      end
    end    
  end
end
