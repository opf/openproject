#-- encoding: UTF-8
# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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
  module Acts
    module Attachable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_attachable(options = {})
          cattr_accessor :attachable_options
          self.attachable_options = {}
          attachable_options[:view_permission] = options.delete(:view_permission) || "view_#{self.name.pluralize.underscore}".to_sym
          attachable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{self.name.pluralize.underscore}".to_sym
          
          has_many :attachments, options.merge(:as => :container,
                                               :order => "#{Attachment.table_name}.created_on",
                                               :dependent => :destroy)
          attr_accessor :unsaved_attachments
          after_initialize :initialize_unsaved_attachments
          send :include, Redmine::Acts::Attachable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end
        
        def attachments_visible?(user=User.current)
          user.allowed_to?(self.class.attachable_options[:view_permission], self.project)
        end
        
        def attachments_deletable?(user=User.current)
          user.allowed_to?(self.class.attachable_options[:delete_permission], self.project)
        end

        def initialize_unsaved_attachments
          @unsaved_attachments ||= []
        end

        module ClassMethods
        end
      end
    end
  end
end
