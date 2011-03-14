# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
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
  module SafeAttributes
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # Declares safe attributes
      # An optional Proc can be given for conditional inclusion
      #
      # Example:
      #   safe_attributes 'title', 'pages'
      #   safe_attributes 'isbn', :if => {|book, user| book.author == user}
      def safe_attributes(*args)
        @safe_attributes ||= []
        if args.empty?
          if superclass < Redmine::SafeAttributes
            superclass.safe_attributes + @safe_attributes
          else
            @safe_attributes
          end
        else
          options = args.last.is_a?(Hash) ? args.pop : {}
          @safe_attributes << [args, options]
          safe_attributes
        end
      end
    end

    # Returns an array that can be safely set by user or current user
    #
    # Example:
    #   book.safe_attributes # => ['title', 'pages']
    #   book.safe_attributes(book.author) # => ['title', 'pages', 'isbn']
    def safe_attribute_names(user=User.current)
      names = []
      self.class.safe_attributes.collect do |attrs, options|
        if options[:if].nil? || options[:if].call(self, user)
          names += attrs.collect(&:to_s)
        end
      end
      names.uniq
    end
    
    # Returns a hash with unsafe attributes removed
    # from the given attrs hash
    # 
    # Example:
    #   book.delete_unsafe_attributes({'title' => 'My book', 'foo' => 'bar'})
    #   # => {'title' => 'My book'}
    def delete_unsafe_attributes(attrs, user=User.current)
      safe = safe_attribute_names(user)
      attrs.dup.delete_if {|k,v| !safe.include?(k)}
    end
    
    # Sets attributes from attrs that are safe
    # attrs is a Hash with string keys
    def safe_attributes=(attrs, user=User.current)
      return unless attrs.is_a?(Hash)
      self.attributes = delete_unsafe_attributes(attrs, user)
    end
  end
end
