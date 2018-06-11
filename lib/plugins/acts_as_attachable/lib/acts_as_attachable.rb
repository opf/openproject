#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Redmine
  module Acts
    module Attachable
      def self.included(base)
        base.extend ClassMethods
      end

      def self.attachables
        @attachables ||= []
      end

      module ClassMethods
        def acts_as_attachable(options = {})
          Redmine::Acts::Attachable.attachables.push(self)
          cattr_accessor :attachable_options
          set_acts_as_attachable_options(options)

          attachments_order = options.delete(:order) || "#{Attachment.table_name}.created_at"
          has_many :attachments, -> {
            order(attachments_order)
          }, options.reverse_merge!(as: :container, dependent: :destroy)

          attr_accessor :attachments_replacements
          send :include, Redmine::Acts::Attachable::InstanceMethods
        end

        private

        def set_acts_as_attachable_options(options)
          name_default = name.pluralize.underscore
          self.attachable_options = {}
          attachable_options[:view_permission] = options.delete(:view_permission) || "view_#{name_default}".to_sym
          attachable_options[:delete_permission] = options.delete(:delete_permission) || "edit_#{name_default}".to_sym
          attachable_options[:add_permission] = options.delete(:add_permission) || "edit_#{name_default}".to_sym
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        def attachments_visible?(user = User.current)
          allowed_to_on_attachment?(user, self.class.attachable_options[:view_permission])
        end

        def attachments_deletable?(user = User.current)
          allowed_to_on_attachment?(user, self.class.attachable_options[:delete_permission])
        end

        def attachments_addable?(user = User.current)
          allowed_to_on_attachment?(user, self.class.attachable_options[:add_permission])
        end

        # Bulk attaches a set of files to an object
        def attach_files(attachments)
          if attachments && attachments.is_a?(Hash)
            attachments.each_value do |attachment|
              file = attachment['file']
              next if !file || file.size.zero?
              self.attachments.build(file: file,
                                     container: self,
                                     description: attachment['description'].to_s.strip,
                                     author: User.current)
            end
          end
        end

        private

        def allowed_to_on_attachment?(user, permissions)
          Array(permissions).any? do |permission|
            user.allowed_to?(permission, project)
          end
        end

        module ClassMethods
          def attachments_addable?(user = User.current)
            Array(attachable_options[:add_permission]).any? do |permission|
              user.allowed_to_globally?(permission)
            end
          end
        end
      end
    end
  end
end
