#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
