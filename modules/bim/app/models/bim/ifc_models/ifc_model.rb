module Bim
  module IfcModels
    class IfcModel < ActiveRecord::Base
      acts_as_attachable delete_permission: :manage_ifc_models,
                         add_permission: :manage_ifc_models,
                         view_permission: :view_ifc_models

      belongs_to :project
      belongs_to :uploader, class_name: 'User', foreign_key: 'uploader_id'

      validates :title, presence: true
      validates :project, presence: true

      scope :defaults, -> { where(is_default: true) }

      %i(ifc xkt metadata).each do |name|
        define_method "#{name}_attachment" do
          get_attached_type(name)
        end

        define_method "#{name}_attachment=" do |file|
          if name == :ifc
            # Also delete xkt
            delete_attachment :xkt
          end

          delete_attachment name
          call = ::Attachments::CreateService
            .bypass_whitelist(user: User.current)
            .call(file: file, container: self, filename: file.original_filename, description: name)

          call.on_failure { Rails.logger.error "Failed to add #{name} attachment: #{call.message}" }
        end
      end

      def converted?
        xkt_attachment.present?
      end

      private

      ##
      # Delete the given named description
      def get_attached_type(key)
        if attachments.loaded?
          attachments.detect { |a| a.description == key.to_s && !a.marked_for_destruction? }
        else
          attachments.find_by_description(key.to_s)
        end
      end

      ##
      # Delete the given named description
      def delete_attachment(key)
        get_attached_type(key)&.destroy
      end
    end
  end
end
