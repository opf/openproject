#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
      extend ActiveSupport::Concern

      included do
        extend ClassMethods
      end

      def self.attachables
        @attachables ||= []
      end

      module ClassMethods
        def acts_as_attachable(options = {})
          Redmine::Acts::Attachable.attachables.push(self)
          class_attribute :attachable_options
          set_acts_as_attachable_options(options)

          attachments_order = options.delete(:order) || "#{Attachment.table_name}.created_at"
          has_many :attachments, -> {
            order(attachments_order)
          }, options.reverse_merge!(as: :container, dependent: :destroy)

          attr_accessor :attachments_replacements,
                        :attachments_claimed
          send :include, Redmine::Acts::Attachable::InstanceMethods

          OpenProject::Deprecation.deprecate_method self, :attach_files
        end

        private

        def set_acts_as_attachable_options(options)
          self.attachable_options = {
            view_permission: view_permission(options),
            delete_permission: delete_permission(options),
            add_on_new_permission: add_on_new_permission(options),
            add_on_persisted_permission: add_on_persisted_permission(options),
            only_user_allowed: only_user_allowed(options),
            modification_blocked: options[:modification_blocked],
            extract_tsv: attachable_extract_tsv_option(options)
          }

          # Because subclasses can have their own attachable_options,
          # we ensure those are also listed.
          Redmine::Acts::Attachable.attachables.push(self) unless Redmine::Acts::Attachable.attachables.include?(self)

          options.except!(:view_permission,
                          :delete_permission,
                          :add_on_new_permission,
                          :add_on_persisted_permission,
                          :add_permission,
                          :only_user_allowed,
                          :modification_blocked,
                          :extract_tsv)
        end

        def view_permission(options)
          options[:view_permission] || view_permission_default
        end

        def delete_permission(options)
          options[:delete_permission] || edit_permission_default
        end

        def add_on_new_permission(options)
          options[:add_on_new_permission] || options[:add_permission] || edit_permission_default
        end

        def add_on_persisted_permission(options)
          options[:add_on_persisted_permission] || options[:add_permission] || edit_permission_default
        end

        def only_user_allowed(options)
          options.fetch(:only_user_allowed, false)
        end

        def view_permission_default
          "view_#{name.pluralize.underscore}".to_sym
        end

        def edit_permission_default
          "edit_#{name.pluralize.underscore}".to_sym
        end

        def attachable_extract_tsv_option(options)
          options.fetch(:extract_tsv, false)
        end
      end

      module InstanceMethods
        extend ActiveSupport::Concern

        included do
          after_save :persist_attachments_claimed

          validate :validate_attachments_claimable

          include InstanceMethods
        end

        class_methods do
          def attachments_addable?(user = User.current)
            user.allowed_to_globally?(attachable_options[:add_on_new_permission]) ||
              user.allowed_to_globally?(attachable_options[:add_on_persisted_permission])
          end

          def attachment_tsv_extracted?
            attachable_options[:extract_tsv]
          end
        end

        module InstanceMethods
          def modification_blocked?
            if (policy = self.class.attachable_options[:modification_blocked])
              return instance_eval &policy
            end

            false
          end

          def attachments_visible?(user = User.current)
            allowed_to_on_attachment?(user, self.class.attachable_options[:view_permission])
          end

          def attachments_deletable?(user = User.current)
            return false if modification_blocked?

            allowed_to_on_attachment?(user, self.class.attachable_options[:delete_permission])
          end

          def attachments_addable?(user = User.current)
            return false if modification_blocked?

            (new_record? && allowed_to_on_attachment?(user, self.class.attachable_options[:add_on_new_permission])) ||
              (persisted? && allowed_to_on_attachment?(user, self.class.attachable_options[:add_on_persisted_permission]))
          end

          # Bulk attaches a set of files to an object
          # @deprecated
          # Either use the already existing Attachments::CreateService or
          # write/extend Services for the attached to object.
          # The service should rely on the attachments_replacements variable.
          # See:
          # * app/services/attachments/set_replacements.rb
          # * app/services/attachments/replace_attachments.rb
          def attach_files(attachments)
            return unless attachments&.is_a?(Hash)

            attachments.each_value do |attachment|
              if attachment['file']
                build_attachments_from_hash(attachment)
              elsif attachment['id']
                memoize_attachment_for_claiming(attachment)
              end
            end
          end

          private

          def allowed_to_on_attachment?(user, permissions)
            Array(permissions).any? do |permission|
              if respond_to?(:project)
                user.allowed_to?(permission, project)
              else
                user.allowed_to_globally?(permission)
              end
            end
          end

          def persist_attachments_claimed
            return unless claimed_attachments?

            Attachment
              .where(id: attachments_claimed.map(&:id))
              .update_all(container_id: id, container_type: attachable_class.name)

            attachments_claimed.clear

            attachments.reload
          end

          def attachable_class
            (Redmine::Acts::Attachable.attachables & self.class.ancestors).first
          end

          def build_attachments_from_hash(attachment_hash)
            if (file = attachment_hash['file']) && file && file.size.positive?
              attachments.build(file: file,
                                container: self,
                                description: attachment_hash['description'].to_s.strip,
                                author: User.current)
            end
          end

          def memoize_attachment_for_claiming(attachment_hash)
            self.attachments_claimed ||= []
            attachment = Attachment.find(attachment_hash['id'])
            self.attachments_claimed << attachment unless id && attachment.container_id == id
          end

          def validate_attachments_claimable
            return unless claimed_attachments?

            if !attachments_addable?
              errors.add :attachments, :not_allowed
            elsif claimed_attachments_of_other_author?
              errors.add :attachments, :does_not_exist
            elsif claimed_attachments_already_claimed?
              errors.add :attachments, :unchangeable
            end
          end

          def claimed_attachments?
            attachments_claimed&.any?
          end

          def claimed_attachments_of_other_author?
            attachments_claimed.any? { |a| a.author != User.current }
          end

          def claimed_attachments_already_claimed?
            attachments_claimed.any?(&:containered?)
          end
        end
      end
    end
  end
end
