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
          attachable_options[:view_permission] = options.delete(:view_permission) || "view_#{name.pluralize.underscore}".to_sym
          attachable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{name.pluralize.underscore}".to_sym

          has_many :attachments, options.reverse_merge!(as: :container,
                                                        order: "#{Attachment.table_name}.created_on",
                                                        dependent: :destroy)
          attr_accessor :unsaved_attachments
          after_initialize :initialize_unsaved_attachments
          send :include, Redmine::Acts::Attachable::InstanceMethods
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def attachments_visible?(user = User.current)
          user.allowed_to?(self.class.attachable_options[:view_permission], project)
        end

        def attachments_deletable?(user = User.current)
          user.allowed_to?(self.class.attachable_options[:delete_permission], project)
        end

        def initialize_unsaved_attachments
          @unsaved_attachments ||= []
        end

        # Bulk attaches a set of files to an object
        def attach_files(attachments)
          if attachments && attachments.is_a?(Hash)
            attachments.each_value do |attachment|
              file = attachment['file']
              next unless file && file.size > 0
              self.attachments.build(file: file,
                                     container: self,
                                     description: attachment['description'].to_s.strip,
                                     author: User.current)
            end
          end
        end

        module ClassMethods
        end
      end
    end
  end
end
